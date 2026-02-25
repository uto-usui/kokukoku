# Watch / Widget ターゲット構成修正 設計ドキュメント

Date: 2026-02-25

## Problem

Phase 2 で追加した Watch / Widget 拡張ターゲットの構成に問題があり、iOS シミュレータへのインストールが失敗する。

### 症状

1. **Widget**: `NSExtensionPrincipalClass` が WidgetKit extension で禁止されているキー → インストール拒否（修正済み）
2. **Watch**: 旧式 WatchKit 2 の2ターゲット構成（container app + extension）を使用。watchOS 26 シミュレータが「not a WatchKit 2 app」としてインストール拒否

### 影響範囲

- `test_sim` (iOS シミュレータでのユニットテスト) が実行不可
- `build_run_sim` (iOS シミュレータでのアプリ起動) が実行不可
- macOS ビルド・テストは影響なし（Watch/Widget は iOS 専用）

## Approach

**アプローチ A: Watch を単一ターゲットに近代化** を採用。

watchOS 7+ では単一ターゲットの Watch アプリが標準。旧 WatchKit 2 アーキテクチャは watchOS 26 で動作しないため、近代化は避けられない。Widget の設定修正と合わせて一括対応する。

Codex レビュー（2026-02-25）で方向性の正しさを確認済み。

## Design

### 1. Watch ターゲット近代化

**現状** (WatchKit 2 — 2ターゲット):

```
KokukokuWatch (container, watchapp2, Sources なし)
  └─ Embed Foundation Extensions
       └─ KokukokuWatchExtension (.appex, watchkit2-extension)
            ├── KokukokuWatchApp.swift (@main)
            └── WatchSessionStore.swift
```

**変更後** (modern — 単一ターゲット):

```
KokukokuWatch (standalone app, com.apple.product-type.application)
  Sources:
    ├── KokukokuWatchApp.swift (@main)
    └── WatchSessionStore.swift
```

#### 1.1 KokukokuWatchExtension ターゲットの完全削除

pbxproj から以下を全て削除:
- ターゲット定義 (`PBXNativeTarget`)
- ビルド設定リスト (`XCBuildConfiguration`, `XCConfigurationList`)
- ソースビルドフェーズ (`PBXSourcesBuildPhase`)
- フレームワーク / リソースビルドフェーズ
- プロダクト参照 (`KokukokuWatchExtension.appex`)
- ビルドファイル参照 (`.swift in Sources`)
- `PBXContainerItemProxy` と `PBXTargetDependency` (メインアプリ → Extension)

#### 1.2 KokukokuWatch ターゲットの変更

- **プロダクトタイプ**: `com.apple.product-type.application.watchapp2` → `com.apple.product-type.application`
- **Sources ビルドフェーズを追加**: `KokukokuWatchApp.swift`, `WatchSessionStore.swift` を含める
- **`Embed Foundation Extensions` ビルドフェーズを削除**: Extension を埋め込む必要がなくなるため
- **ビルド設定の調整**:
  - 維持: `GENERATE_INFOPLIST_FILE = YES`
  - 維持: `INFOPLIST_KEY_WKCompanionAppBundleIdentifier = "com.uto-usui.Kokukoku"`
  - 維持: `PRODUCT_BUNDLE_IDENTIFIER = "com.uto-usui.Kokukoku.watchkitapp"`
  - 維持: `SDKROOT = watchos`, `WATCHOS_DEPLOYMENT_TARGET = 26.2`
  - 削除: Extension 固有の plist キー (`NSExtension`, `WKAppBundleIdentifier`)
  - プロジェクトに合わせる: `SWIFT_VERSION`

#### 1.3 メインアプリ側の変更

- **`Embed Watch Content` はそのまま維持** — KokukokuWatch.app を iOS アプリの `Watch/` に埋め込む仕組みは変わらない
- **ターゲット依存関係の更新** — `KokukokuWatchExtension` への依存を `KokukokuWatch` への依存に差し替え（または既存の Watch 依存をそのまま維持）

### 2. Widget ターゲット修正

#### 2.1 Info.plist マージ方式に修正

- `GENERATE_INFOPLIST_FILE` を `YES` に変更 (Debug / Release 両方)
- `INFOPLIST_FILE = KokukokuWidget/Info.plist` を維持（マージソースとして使用）
- `INFOPLIST_KEY_CFBundleDisplayName = "Kokukoku Widget"` をビルド設定に追加
- 手動 Info.plist は `NSExtension` 辞書のみ保持（`NSExtensionPointIdentifier` のネスト構造は INFOPLIST_KEY_ では生成不可のため）
- `NSExtensionPrincipalClass` は削除済み（WidgetKit で禁止）

### 3. ActivityAttributes 重複解消

**現状**: 同一の `KokukokuActivityAttributes` が2ファイルに存在
- `Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift` (メインアプリ、`#if os(iOS) && canImport(ActivityKit)` ガード付き)
- `KokukokuWidget/KokukokuActivityAttributes.swift` (Widget、ガードなし)

**変更**:
- `Kokukoku/Shared/LiveActivity/KokukokuActivityAttributes.swift` を正とする
- `#if` ガードを外す（Widget 側でも使えるように）
- このファイルを Widget ターゲットの Sources にも追加 (pbxproj で両ターゲットに含める)
- `KokukokuWidget/KokukokuActivityAttributes.swift` を削除

### 4. スキーム整備

- スキーム変更は不要と判明。Watch / Widget はメインアプリの暗黙的依存（Embed フェーズ）でビルドされる
- スキームに明示追加すると macOS ビルド時に watchOS/iOS 専用ターゲットの署名エラーが発生する

### 5. ファイルシステム整理

- `KokukokuWatchExtension/` ディレクトリ内のソースファイルを `KokukokuWatch/` に移動（物理パス変更に合わせて pbxproj のファイル参照も更新）
- または pbxproj のパス参照だけ変更して物理ファイルはそのまま（ビルドが通れば OK）

## Verification Gates

修正完了後に以下が全て通ること:

1. `make build-macos` — macOS ビルド成功
2. `make test-macos` — ユニットテスト全パス (22 tests)
3. `build_sim` (XcodeBuildMCP) — iOS シミュレータビルド成功
4. `test_sim -only-testing:KokukokuTests` — iOS シミュレータでユニットテスト全パス
5. `build_run_sim` — iOS シミュレータでアプリが起動する

## Out of Scope

- Watch / Widget の機能テスト追加（別タスク）
- Watch / Widget 専用スキームの作成（Build タブ追加で十分）
- 共有フレームワーク / Swift Package の導入（YAGNI）
