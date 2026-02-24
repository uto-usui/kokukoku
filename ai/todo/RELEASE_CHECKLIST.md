# Kokukoku Phase 1 リリースチェックリスト

## 1. 機能受け入れ
- [ ] Focus -> Short Break -> Focus の基本遷移が正しい
- [ ] 4回目Focus完了でLong Breakに遷移する
- [ ] Start / Pause / Resume / Reset / Skip が期待通り動作する
- [ ] `Stop at next boundary` が次境界で停止する
- [ ] `Stop at long break` が長休憩境界で停止する
- [ ] Auto-start OFF で全Boundary停止する

## 2. 時間整合性
- [ ] `endDate` 基準で残り時間が計算される
- [ ] バックグラウンド復帰後に残り時間が破綻しない
- [ ] 端末時刻変化に対して大きな不整合が起きない

## 3. 通知
- [ ] 権限未許可時の導線が崩れない
- [ ] running中に1件だけ通知予約される
- [ ] Pause/Reset/Skipで不要通知がキャンセルされる
- [ ] Sound ON / Silent の設定が反映される

## 4. データ
- [ ] セッション完了時に `SessionRecord` が保存される
- [ ] Skip時に `skipped = true` で保存される
- [ ] 履歴画面で Focus/Break/All フィルタが動作する

## 5. UI/UX
- [ ] iOSは `NavigationStack` で違和感なく操作できる
- [ ] macOSは `NavigationSplitView` で違和感なく操作できる
- [ ] Timer表示は `monospacedDigit` で桁ブレしない
- [ ] 主要操作ボタンの階層（primary/secondary）が明確
- [ ] Dynamic Typeで情報欠落が起きない
- [ ] VoiceOverで主要操作に到達できる

## 6. 品質ゲート
- [ ] `make lint` が通る
- [ ] `make test-macos` が通る
- [ ] 重大クラッシュがない
- [ ] TODOコメントや暫定コードが残っていない
