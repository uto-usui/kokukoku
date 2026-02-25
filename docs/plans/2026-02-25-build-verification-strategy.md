# LLM 開発におけるビルド検証戦略

Date: 2026-02-25

## 問題

Phase 2 の Watch/Widget 実装で、macOS ユニットテスト 22/22 PASS にも関わらず iOS シミュレータビルドが失敗していた。4 タスク分の pbxproj 変更を積み上げてから初めてビルドし、複合エラーの切り分けが困難になった。

### 発生したバグの分類

| バグ | 検出可能なタイミング | テストで検出可能か |
|---|---|---|
| WatchKit 2 → watchOS 26 非互換 | iOS ビルド時 | No（macOS ビルドでは Watch スキップ） |
| NSExtension ネスト plist 不正 | iOS インストール時 | No（ビルドは通る） |
| `nil as Any` → plist 型エラー | 実行時 | Yes（ペイロード構築を分離すれば） |
| Watch idle 時 00:00 表示 | 実行時 | Yes（Watch 表示ロジックのテスト） |

テストだけでは検出できない問題が過半数。**ビルド+実行の検証が必須**。

## 実測データ

Kokukoku プロジェクト（Swift 6, 22 テスト, 5 ターゲット）の各操作の所要時間:

| 操作 | インクリメンタル | クリーン |
|---|---|---|
| `make build-macos` | ~3.5s | ~3.0s |
| `build_sim` (iOS) | ~8.4s | ~3.6s |
| `make test-macos` | ~6.7s | — |
| `build_run_sim` (iOS, install+launch) | ~15s (推定) | — |

**現時点ではプロジェクトが小さく、ビルド時間は無視できるレベル。** ただしプロジェクト成長に伴いこの前提は変わる。

## 3 段階ビルド検証アプローチ

### Step 1: Spike ビルド（プラン検証）

**タイミング**: プラン作成後、本実装前
**目的**: プランの前提（ターゲット構成、plist 規則等）が正しいか検証
**方法**: 最小限の変更（1 ファイル）だけして `build_sim` 実行

**適用条件**: 変更対象が以下を含む場合のみ:
- `project.pbxproj`
- `*.xcscheme`
- `Info.plist`
- 新規ターゲット追加

**コスト**: 低（1 回のビルド ~8s + 最小変更の作成時間）
**効果**: 高（今回の WatchKit 2 問題、NSExtension 問題はここで検出できた）

### Step 2: バックグラウンドビルド（タスク間）

**タイミング**: 各タスクのコミット後
**目的**: 変更が他のターゲットを壊していないか即座に確認
**方法**: `run_in_background` で `build_sim` を実行、メインエージェントは次タスクに着手

**運用ルール**（Codex レビューで指摘、機械強制すべき点）:
1. **同時に 1 ジョブ**: 前回のビルドが完了してから次を起動
2. **コミット SHA 紐付け**: どのコミットのビルドか明確にする
3. **次コミット前に結果確認**: ビルド失敗を見落とさない

**構成変更クラス**（pbxproj/xcscheme/Info.plist 変更を含む場合）:
- `build_sim` ではなく `build_run_sim` を使う（インストール時エラーも検出）

**コスト**: 中（タスクあたり ~8-15s の待ち時間、ただしバックグラウンドなので実質 0）
**効果**: 高（複合エラーの蓄積を防止）

### Step 3: フル検証ゲート（最終）

**タイミング**: 全タスク完了後
**方法**: macOS build + macOS test + iOS build + iOS test + simctl launch
**自動化**: `make ci` に iOS ビルドを追加、GitHub Actions の required check にする

**コスト**: 低〜中（CI で自動実行、手動コスト 0）
**効果**: 最高（最終防波堤）

## 補完: テスト側の改善

ビルド検証だけでは検出できない問題（`nil as Any` 等）への対策:

### 1. エラー握りつぶし防止

```swift
// Before: サイレント失敗
catch { }

// After: Debug でクラッシュ、Release でログ
catch {
    assertionFailure("[WatchSync] updateApplicationContext failed: \(error)")
}
```

### 2. ペイロード構築の分離とテスト

```swift
// テスト可能な純粋関数に分離
func buildSyncContext(snapshot: TimerSnapshot, config: TimerConfig, now: Date) -> [String: Any]

// テスト
@Test func syncContext_nilEndDate_excludesKey() {
    let context = buildSyncContext(snapshot: .idle, config: .default, now: Date())
    #expect(context["endDateEpoch"] == nil) // キーが存在しない
    #expect(context["sessionDurationSec"] as? Int == 1500) // 25分
}
```

### 3. `#if os(iOS)` コードのロジック分離

条件コンパイル内のロジックは macOS テストでカバーできない。ビジネスロジックを条件コンパイルの外に出し、プラットフォーム API 呼び出しだけを薄いラッパーに閉じ込める。

## 費用対効果の評価

### 現在のプロジェクト規模での評価

ビルド時間が ~3-8s と極めて短いため、**全ステップのオーバーヘッドは事実上ゼロ**。今すぐ全て導入しても開発速度に影響しない。

### プロジェクト成長後の評価

ビルド時間が 30s-2min に伸びた場合:

| Step | 追加待ち時間 | 開発速度への影響 | リスク低減 | 推奨 |
|---|---|---|---|---|
| Spike | 1 回/プラン | なし（プラン後に 1 回だけ） | 高 | 常に実施 |
| BG build (全タスク) | 0（バックグラウンド） | なし | 中 | 常に実施 |
| BG build_run (構成変更時) | 0（バックグラウンド） | なし | 高 | 構成変更時のみ |
| Full gate | 1 回/ブランチ | CI で自動（手動 0） | 最高 | 常に実施 |

**バックグラウンド実行により、ビルド時間が伸びても開発速度への影響はゼロに近い。**

### 定量比較: 今回の巻き戻りコスト

今回の Phase 2 ターゲット修正で発生した追加コスト:
- 設計ドキュメント作成: ~30 min
- 6 タスクの実装と検証: ~2 hours
- WatchConnectivity バグの調査と修正: ~1 hour
- **合計: ~3.5 hours の手戻り**

提案する検証ステップの 1 回あたりコスト:
- Spike build: ~10 seconds
- バックグラウンド build: ~0 seconds（並行）
- **合計: ~10 seconds**

**ROI: 10 秒の投資で 3.5 時間の手戻りを防止。**

## Codex レビュー所見

- 提案の方向性は**妥当**
- Step 2 は「運用ルール」ではなく「機械強制」にしないと LLM が読み飛ばすリスクがある
- `build_sim` だけでなく構成変更時は `build_run_sim` を使うべき
- CI に iOS ビルドを追加しないと最終防波堤がない
- Watch 同期経路のテストがなく、plist 型ミスの回帰を検出できない

## 実装アクション

優先度順:

1. [ ] `make ci` に `build-ios` ターゲットを追加
2. [ ] `.github/workflows/ci.yml` に iOS シミュレータビルドステップを追加
3. [ ] `WatchConnectivityService` の catch に `assertionFailure` を追加
4. [ ] sync ペイロード構築を純粋関数に分離しテスト追加
5. [ ] CLAUDE.md に Build Verification Strategy セクションを追加
6. [ ] subagent-driven-development のフローにバックグラウンドビルドを組み込み
