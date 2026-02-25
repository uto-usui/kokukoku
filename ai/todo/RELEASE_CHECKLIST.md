# Kokukoku Phase 1 リリースチェックリスト

## 1. 機能受け入れ
- [x] Focus -> Short Break -> Focus の基本遷移が正しい
- [x] 4回目Focus完了でLong Breakに遷移する
- [x] Start / Pause / Resume / Reset / Skip が期待通り動作する
- [x] `Stop at next boundary` が次境界で停止する
- [x] `Stop at long break` が長休憩境界で停止する
- [x] Auto-start OFF で全Boundary停止する

## 2. 時間整合性
- [x] `endDate` 基準で残り時間が計算される
- [x] バックグラウンド復帰後に残り時間が破綻しない
- [x] 端末時刻変化に対して大きな不整合が起きない

## 3. 通知
- [x] 権限未許可時の導線が崩れない
- [x] running中に1件だけ通知予約される
- [x] Pause/Reset/Skipで不要通知がキャンセルされる
- [x] Sound ON / Silent の設定が反映される

## 4. データ
- [x] セッション完了時に `SessionRecord` が保存される
- [x] Skip時に `skipped = true` で保存される
- [x] 履歴画面で Focus/Break/All フィルタが動作する

## 5. UI/UX
- [x] iOSは `NavigationStack` で違和感なく操作できる
- [x] macOSは `NavigationSplitView` で違和感なく操作できる
- [x] Timer表示は `monospacedDigit` で桁ブレしない
- [x] 主要操作ボタンの階層（primary/secondary）が明確
- [x] Dynamic Typeで情報欠落が起きない
- [x] VoiceOverで主要操作に到達できる

## 6. 品質ゲート
- [x] `make lint` が通る
- [x] `make test-macos` が通る
- [x] 重大クラッシュがない
- [x] TODOコメントや暫定コードが残っていない
