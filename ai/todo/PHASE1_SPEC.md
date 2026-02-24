# Kokukoku Phase 1 仕様

## 1. 目的
- 実装時の判断ブレを防ぐため、Phase 1（MVP）の仕様を固定する。
- `PLAN.md` と `TASKS.md` の実装対象を、動作レベルで明文化する。

## 2. 用語
- `Focus`: 作業セッション
- `Short Break`: 短休憩セッション
- `Long Break`: 長休憩セッション
- `Cycle`: Focusを起点に、休憩を挟んで次Focusまで進む単位
- `Boundary`: セッション終了時点（次セッションに遷移する境目）

## 3. デフォルト設定
- Focus: `25分`
- Short Break: `5分`
- Long Break: `15分`
- Long Break頻度: `Focus 4回ごと`
- Auto-start: `ON`
- 通知: `Sound ON`（設定でSilentへ切替可）

## 4. 状態モデル
- `TimerState`
  - `idle`: 未開始
  - `running`: 動作中
  - `paused`: 一時停止中
  - `completed`: 現在セッション完了（遷移直前/直後の表現で利用）
- `SessionType`
  - `focus`
  - `shortBreak`
  - `longBreak`
- `BoundaryStopPolicy`
  - `none`
  - `stopAtNextBoundary`
  - `stopAtLongBreak`

## 5. セッション遷移ルール
- Focus完了時:
  - 完了Focus数がLong Break頻度に達したら `Long Break` へ
  - それ以外は `Short Break` へ
- Break完了時:
  - 常に `Focus` へ
- `Skip`:
  - 現在セッションを即時終了として扱い、次セッションへ進む
  - FocusをSkipした場合でも、Focusカウントは進める（サイクル進行）
  - Pause状態でSkipした場合、次セッションもPause状態のまま待機する（自動再生しない）
  - 履歴上は `skipped = true`
- `Reset`:
  - セッションを停止し、`Focus` 開始状態に戻す
  - サイクルカウントを `0` に戻す

## 6. 境界停止ルール
- `stopAtNextBoundary`:
  - 次のBoundaryで自動遷移を止める
  - 停止後は `idle` 扱いで次セッション開始待ち
- `stopAtLongBreak`:
  - Long Break開始境界に達した時点で停止
  - それ以外のBoundaryでは通常どおり進む
- Auto-startがOFFの場合:
  - すべてのBoundaryで停止（明示開始待ち）

## 7. 時間計算ルール
- 実時間カウントは `endDate` 基準で算出する。
- 残り時間:
  - `max(0, endDate - now)`
- 復帰時:
  - アプリ再開時に `now` との差分から再計算
  - 負値ならセッション完了として遷移処理

## 8. 通知ルール
- 通知権限は最初のタイマー開始前後で要求する。
- `running` 中のみ、現在セッション終端時刻に通知を1件スケジュールする。
- 一時停止/リセット/スキップ時は未発火通知をキャンセルして再設定する。
- サウンド設定:
  - `Sound ON`: 既定音付き通知
  - `Silent`: 無音通知

## 9. 履歴ルール
- 保存単位: セッションごと
- `SessionRecord` の最低フィールド:
  - `id`
  - `sessionType`
  - `startedAt`
  - `endedAt`
  - `plannedDurationSec`
  - `actualDurationSec`
  - `completed`
  - `skipped`
- 保存タイミング:
  - セッション終了時（完了/スキップ）

## 10. UIルール（Phase 1）
- iOS:
  - `NavigationStack` 基本
- macOS:
  - `NavigationSplitView` 基本
- タイマー数字:
  - `monospacedDigit`
- 主要操作:
  - `Start`: `.borderedProminent`
  - その他: `.bordered`

## 11. 非対象（Phase 1）
- MenuBarExtra
- Widget / Live Activity
- Apple Watch
- Focus Mode連携
