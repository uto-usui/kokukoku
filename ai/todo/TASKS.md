# Kokukoku MVP Tasks

## M0. Planning Lock (Before Implementation)
- [x] Finalize Phase 1 scope boundaries from `PLAN.md`.
- [x] Confirm behavior details against `PHASE1_SPEC.md`.
- [x] Lock UI composition rules:
  - [x] Navigation model (`NavigationStack` on iOS, `NavigationSplitView` on macOS)
  - [x] Primary/secondary button styles
  - [x] Timer typography (`monospacedDigit`)
- [x] Lock styling rules:
  - [x] Semantic color-first policy
  - [x] Timer/session UIはモノトーン運用（強い色はprimary action中心）
  - [x] 有彩色はprimary actionに限定（Start/Resume同色、Pauseは別色可）
- [x] Lock notification default: `Sound ON` with optional `Silent`.

## M1. Domain and Timer Engine
- [x] Define `TimerState`, `SessionType`, `TimerConfig`, `TimerSnapshot`.
- [x] Define `BoundaryStopPolicy`:
  - [x] none
  - [x] stopAtNextBoundary
  - [x] stopAtLongBreak
- [x] Implement `TimerEngine` transitions:
  - [x] Focus -> Short Break
  - [x] Focus -> Long Break (every 4th focus)
  - [x] Break -> Focus
  - [x] Manual skip and reset
- [x] Implement `endDate`-based remaining time calculation.
- [x] Add unit tests for transition correctness.
- [x] Add unit tests for boundary stop behavior.

## M2. Main Timer UI
- [x] Build main timer screen with:
  - [x] Session label
  - [x] Remaining time
  - [x] Progress ring/bar
  - [x] Start/Pause/Resume/Reset/Skip buttons
- [x] Add per-boundary stop control UI:
  - [x] "Stop at next boundary"
  - [x] "Stop at long break"
- [x] Apply native component styles:
  - [x] Primary action as `.borderedProminent`
  - [x] Secondary actions as `.bordered`
  - [x] Progress visualization with lightweight animation
- [x] Verify iOS/macOS interaction parity.

## M3. Notification Flow
- [x] Request notification permission on first relevant action.
- [x] Schedule/cancel local notifications based on current `endDate`.
- [x] Apply notification setting:
  - [x] Sound ON (default)
  - [x] Silent mode
- [x] Validate behavior on app background/restore.

## M4. Settings
- [x] Add settings screen for:
  - [x] Focus/Short/Long durations
  - [x] Long break frequency
  - [x] Auto-start toggle
  - [x] Boundary stop policy controls
  - [x] Notification sound toggle
- [x] Persist settings and apply immediately to next cycle.

## M5. History
- [x] Define `SessionRecord` model (type, start/end, duration, completed/skipped).
- [x] Store record when each session ends.
- [x] Create history list screen with basic filters (Focus/Break/All).
- [x] Match history UI to native patterns (`List` + segmented filter picker).

## M6. Polish and Quality
- [x] Improve accessibility labels and dynamic type behavior.
- [x] Respect Reduce Motion / contrast settings.
- [x] Add basic app icons + launch polish.
- [x] Add tests for:
  - [x] endDate restore
  - [x] long-break cycle count
- [x] Final validation:
  - [x] `make lint`
  - [x] `make test-macos`
- [x] Pass all checks in `RELEASE_CHECKLIST.md`.

## Phase 2 Backlog (Not in MVP)
- [x] MenuBarExtra (macOS)
- [x] Widget / Live Activity (iOS)
- [x] Apple Watch companion
- [x] Focus mode integration

## P2-Fix. Watch / Widget ターゲット構成修正

設計: `docs/plans/2026-02-25-watch-widget-target-fix-design.md`
実装計画: `docs/plans/2026-02-25-watch-widget-target-fix.md`

- [x] Task 1: KokukokuWatchExtension ターゲットを pbxproj から完全削除
- [x] Task 2: KokukokuWatch を modern 単一ターゲット (product-type: application) に変換
- [x] Task 3: Widget の Info.plist 修正（GENERATE + 手動 plist マージ方式）
- [x] Task 4: ActivityAttributes の重複解消（共有ソース1本化）
- [-] Task 5: スキーム更新 → 不要（暗黙的依存でビルドされる）
- [x] Task 6: 全検証ゲート通過
  - [x] `make build-macos` 成功
  - [x] `make test-macos` 全パス (22/22)
  - [x] `build_sim` (iOS Simulator) 成功
  - [x] `test_sim -only-testing:KokukokuTests` 全パス (22/22)
  - [x] `simctl launch` でアプリ起動確認

## Phase 2 Verification (Manual)
- [x] iPhone + Apple Watch のペアシミュレータで `Kokukoku` を起動する
- [x] iPhoneでタイマー開始/一時停止/再開したとき、Watchの残り時間と状態が追従する
- [x] Watchの `Start/Pause/Reset/Skip` 操作がiPhone側のタイマーに反映される

## Build Verification Strategy

設計: `docs/plans/2026-02-25-build-verification-strategy.md`

- [x] Task 1: `make ci` に `build-ios` ターゲット追加 + CI ワークフロー更新
- [x] Task 2: `WatchConnectivityService` の catch に `assertionFailure` 追加
- [x] Task 3: sync ペイロード構築を純粋関数に分離しテスト追加
- [x] Task 4: CLAUDE.md に Build Verification Strategy セクション追加

## Audio & Haptics

設計: `docs/plans/2026-02-25-audio-haptics-design.md`

### Haptics 拡充
- [x] Start / Pause / Resume に UIImpactFeedbackGenerator 追加（TimerStore.swift、各1行）
- [x] 手動確認（iOS Simulator or 実機）

### Focus Mode オプトアウト
- [x] TimerConfig に `respectFocusMode: Bool` 追加（default: true）
- [x] effectiveNotificationSoundEnabled の条件分岐修正
- [x] UserTimerPreferences に `respectFocusMode` 追加
- [x] persistPreferences / applyPreferences に読み書き追加
- [x] TimerStore に `updateRespectFocusMode()` 追加
- [x] SettingsScreen "System Focus" セクションに Toggle 追加
- [x] Unit test: respectFocusMode ON/OFF × isFocused の組み合わせ

### アンビエントノイズ（ピンクノイズ）
モックアップ: `mockups/ambient-noise.html`
確定パラメータ: Pink noise, Cutoff 648 Hz, Resonance 1.0, Volume 50%, Fade 1.0s

- [x] AmbientNoiseServicing protocol 定義
- [x] AmbientNoiseService 実装（AVAudioEngine + AVAudioSourceNode + BiquadFilter、ピンクノイズ）
- [x] TimerConfig に `ambientNoiseEnabled` / `ambientNoiseVolume` 追加
- [x] UserTimerPreferences に追加 + persist/apply
- [x] TimerStore にライフサイクル制御追加（start/pause/resume/complete/scenePhase）
- [x] SettingsScreen "Audio" セクション追加（Toggle + Volume Slider）
- [x] Unit test: ライフサイクル制御（mock protocol）
- [x] Unit test: 設定の永続化
- [x] 手動確認（音質・ボリューム・他アプリとの共存）

## Generative Mode (Pulse)

設計: `docs/plans/2026-02-25-generative-mode-design.md`
モックアップ: `mockups/pulse.html`

- [x] 設計ドキュメント作成
- [x] HTML モックアップ作成・パラメータ確定
- [x] Swift 実装計画作成
- [x] Swift 実装
  - [x] GenerativeVisual protocol + PulseVisual
  - [x] GenerativeTimerView (Canvas + TimelineView)
  - [x] TimerScreen integration
  - [x] Settings toggle (generativeModeEnabled)
  - [x] Unit tests (heartbeat envelope, ripple, decay, settings)
  - [x] Accessibility (reduceMotion fallback, VoiceOver)

## Material Surface & Typography

設計: `docs/plans/2026-02-25-material-surface-typography.md`

- [x] `.ultraThinMaterial` 背景でビブランシー有効化
- [x] GrainOverlay（128x128 CGImage タイル、opacity 0.04）
- [x] タイマー数字: 100pt thin weight, `.monospacedDigit()`, `.contentTransition(.numericText)`
- [x] ラベル: `.subheadline` / `.caption`, `.foregroundStyle(.secondary)`
- [x] タイトル「Kokukoku」: `.foregroundStyle(.tertiary)`, running 中 opacity 0
- [x] プライマリボタン: `Capsule().fill(.tertiary)`, `.buttonStyle(.plain)`
- [x] Accessibility: Increase Contrast でグレイン無効、Reduce Motion でアニメ無効

## Control Hierarchy Redesign

設計: `docs/plans/2026-02-25-control-hierarchy-redesign.md`

- [x] ツールバー統合: 2アイコン（History, Settings）→ 単一 `ellipsis` Menu
- [x] Menu 項目: Sound トグル → History → Settings...（頻度順）
- [x] History / Settings: `.sheet()` + `NavigationStack` + × ボタン
- [x] `matchedTransitionSource` / `.navigationTransition(.zoom)` で zoom 遷移
- [x] `.toolbarBackgroundVisibility(.hidden)` でナビバーガラス非表示
- [x] Reset/Skip: paused 時のみインライン表示
- [x] `...` Menu: 全状態で常時表示（running 中も非表示にしない）
- [x] macOS ビルド / iOS ビルド検証通過

## Narrative Mode Rename & Style Unification

Generative Mode を Narrative Mode にリネームし、標準モードと統一されたスタイルを適用する。
**Status: ペンディング** — コードは残存するが Settings UI からトグルを削除し、ユーザーからはアクセス不可。将来的にビジュアル表現を再検討後に復活予定。

- [x] Rename: generativeMode → narrativeMode（TimerConfig, UserTimerPreferences, SettingsScreen, TimerScreen, コード・コメント全般）
- [x] Directory/File rename: Generative/ → Narrative/, GenerativeTimerView → NarrativeTimerView, GenerativeVisual → NarrativeVisual
- [x] Narrative body: 独立レイアウト廃止 → 標準モードの背景レイヤーとしてキャンバスを配置（UI は完全に標準モードと同一）
- [x] NarrativeTimerView: テキストオーバーレイ除去、キャンバス描画のみの純粋なビューに簡素化
- [x] Settings から Appearance セクション（Narrative Mode トグル）を非表示化
- [x] Build 検証（macOS + iOS）

## Desktop App Style Unification

macOS 固有の UI スタイルを全体のデザイン言語に合わせる。

- [x] MenuBarTimerView: `.borderedProminent` + orange/blue tint → `Capsule().fill(.tertiary)` + `.buttonStyle(.plain)`（統一スタイル）
- [x] MenuBarTimerView: timer digits を 34pt thin weight に変更
- [x] macOS detail view: `.toolbarBackgroundVisibility(.hidden, for: .windowToolbar)` 適用
- [x] Build 検証（macOS + iOS）

## Settings Screen Redesign

Settings 画面のセクション構成・項目順序・文言を整理。Codex レビューを経て最終確定。

- [x] Notifications / Audio / System Focus → Sound セクションに統合
- [x] 診断テキスト削除（Permission, Effective Sound）
- [x] 説明注釈削除（Focus Mode 説明文）
- [x] Sound → Notifications + Ambient Noise に再分割（Codex フィードバック反映）
- [x] Long Break frequency を Durations → Behavior に移動
- [x] 未使用 `appearanceSection` プロパティ削除
- [x] 「Respect Focus Mode」→「Mute in Focus」に文言変更
- [x] セクション順: Durations → Behavior → Ambient Noise → Notifications（日常調整先、システム連携後）
- [x] Notifications 内順序: Notification Sound → Allow Focus Access → Mute in Focus（権限付与→挙動の順）
- [x] Build 検証（macOS + iOS テスト全パス）
