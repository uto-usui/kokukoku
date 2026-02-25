# Audio & Haptics Design

## Goal

タイマーのフィードバック体験を拡充する。ハプティクス拡充、Focus Mode オプトアウト、アンビエントノイズ生成の 3 機能を追加する。

## Scope

| 機能 | 状態 | 優先度 |
|---|---|---|
| Haptics 拡充 | 実装する | 高 |
| Focus Mode オプトアウト | 実装する | 中 |
| アンビエントノイズ（生成） | 実装する | 中 |
| 画面フラッシュ | ペンディング | — |
| カスタム完了音 | 不要 | — |
| バイブレーション専用モード | 不要（システム音量で自動的に実現） | — |

## 1. Haptics 拡充

### 現状

`completeCurrentSession` 内で `UINotificationFeedbackGenerator().notificationOccurred(.success)` のみ（iOS）。

### 変更

| トリガー | ハプティクス | コード |
|---|---|---|
| セッション完了（全境界遷移） | `.notificationOccurred(.success)` | 変更なし（既存） |
| Start タップ | `.impactOccurred(.medium)` | `start()` に追加 |
| Pause タップ | `.impactOccurred(.light)` | `pause()` に追加 |
| Resume タップ | `.impactOccurred(.medium)` | `resume()` に追加 |

macOS は no-op（`#if os(iOS)`）。変更箇所は `TimerStore.swift` の `start()`, `pause()`, `resume()` に各 1 行追加のみ。

## 2. Focus Mode オプトアウト

### 現状

`effectiveNotificationSoundEnabled` が Focus Mode 中は自動で `false` になる。オプトアウト不可。

### 変更

**TimerConfig に追加:**

```swift
var respectFocusMode: Bool = true
```

**effectiveNotificationSoundEnabled の変更:**

```swift
var effectiveNotificationSoundEnabled: Bool {
    if self.config.respectFocusMode {
        return self.config.notificationSoundEnabled && !self.focusModeStatus.isFocused
    }
    return self.config.notificationSoundEnabled
}
```

**UserTimerPreferences に追加:** `respectFocusMode: Bool`

**persistPreferences / applyPreferences** に読み書き追加。

**SettingsScreen:** "System Focus" セクションに Toggle 追加:

```swift
Toggle(
    "Respect Focus Mode",
    isOn: Binding(
        get: { self.store.config.respectFocusMode },
        set: { self.store.updateRespectFocusMode($0) }
    )
)
```

説明文を変更: "When enabled, notification sound is muted while Focus is active."

デフォルトは ON（現状の動作を維持）。

## 3. アンビエントノイズ（ピンクノイズ）

### Concept

Focus セッション中にピンクノイズをリアルタイム生成して再生する。音をオンにした人だけが使える控えめなオプション。

### Direction (from mockup)

HTML モックアップ (`mockups/ambient-noise.html`) で White / Pink / Brown / Campfire (プロシージャル焚き火) を比較検証した結果:
- **Pink ノイズ + ローパスフィルター** を採用
- Campfire（焚き火）はクオリティが十分でないためドロップ
- ノイズ種の選択 UI は不要（Pink 固定）

### Confirmed Parameters (from mockup)

```
noiseType     = pink (Voss-McCartney algorithm)
cutoffHz      = 648
resonance     = 1.0
volume        = 0.5 (default, user adjustable 0.0-1.0)
fadeInSec     = 1.0
fadeOutSec    = 1.0
```

### Architecture

```
Services/
└── AmbientNoiseService.swift   # AVAudioEngine + AVAudioSourceNode + BiquadFilter
```

**技術スタック:**
- `AVAudioEngine` + `AVAudioSourceNode` でリアルタイムピンクノイズ生成
- `AVAudioUnitEQ` または `AVAudioUnitEffect` でローパスフィルター (648 Hz, Q=1.0)
- `AVAudioSession` カテゴリ: `.playback` + `.mixWithOthers`（Spotify 等と共存）
- Background Audio entitlement: 不要（バックグラウンドではノイズ停止）

**Audio pipeline:**

```
AVAudioSourceNode → AVAudioUnitEQ (lowpass 648Hz) → AVAudioMixerNode → output
   (pink noise)         (filter)                      (volume+fade)
```

### Pink Noise Generation (Voss-McCartney)

```swift
// 概念的なコード
private let rowCount = 16
private var runningSum: Float = 0
private var rows = [Float](repeating: 0, count: 16)

func generatePinkNoise(buffer: UnsafeMutablePointer<Float>, frameCount: Int) {
    for i in 0..<frameCount {
        let white = Float.random(in: -1...1)
        let row = Int.random(in: 0..<rowCount)
        runningSum -= rows[row]
        rows[row] = white / Float(rowCount)
        runningSum += rows[row]
        buffer[i] = (runningSum + white / Float(rowCount)) * 0.5
    }
}
```

### Settings Integration

**TimerConfig に追加:**

```swift
var ambientNoiseEnabled: Bool = false
var ambientNoiseVolume: Double = 0.5  // 0.0 ... 1.0
```

**SettingsScreen:** "Audio" セクション（新規）に追加:

```
Section("Audio") {
    Toggle("Ambient Noise", isOn: ...)
    if config.ambientNoiseEnabled {
        Slider("Volume", value: ..., in: 0...1)
    }
}
```

`notificationSoundEnabled` が ON の場合のみ `ambientNoiseEnabled` を表示可能とする（音を完全にオフにしている人には見せない）。

### Lifecycle

| イベント | 動作 |
|---|---|
| Focus セッション開始（Start / Resume） | ノイズ再生開始（1.0s フェードイン） |
| Pause | ノイズ停止（1.0s フェードアウト） |
| Break セッション開始 | ノイズ停止（1.0s フェードアウト） |
| セッション完了 → 次の Focus が自動開始 | ノイズ再開 |
| アプリがバックグラウンドへ | ノイズ停止 |
| アプリがフォアグラウンドに復帰 + Focus running | ノイズ再開 |
| Reset | ノイズ停止 |

TimerStore が `AmbientNoiseService` を保持し、`start()` / `pause()` / `resume()` / `completeCurrentSession()` / `handleScenePhaseChange()` でライフサイクルを制御。

### Protocol

```swift
protocol AmbientNoiseServicing {
    func start(volume: Double)
    func stop()
    func setVolume(_ volume: Double)
}
```

テスト時はモック注入可能。

### Platform

- iOS: `AVAudioEngine` フル対応
- macOS: `AVAudioEngine` フル対応（同じコードで動作）
- watchOS: 非対応（スピーカー品質の制約）

`#if os(iOS) || os(macOS)` でガード。

## Testing Strategy

| Target | Test Content | Method |
|---|---|---|
| Haptics | 副作用のため自動テスト不要 | 手動確認 |
| Focus Mode opt-out | respectFocusMode ON/OFF × isFocused → effectiveNotificationSoundEnabled | Unit test |
| Focus Mode persistence | respectFocusMode の persist/apply | Unit test (既存パターン) |
| AmbientNoiseService | start/stop lifecycle | Unit test (mock protocol) |
| Ambient noise lifecycle | Focus start → noise start, Pause → noise stop, Break → noise stop | Unit test (mock) |
| Ambient noise persistence | ambientNoiseEnabled / volume の persist/apply | Unit test (既存パターン) |
| Noise generation | 手動確認（音質・ボリューム・他アプリとの共存） | 手動 |

## Mockup

`mockups/ambient-noise.html` にパラメータ確定済みの Web Audio API モックアップが存在する。Pink ノイズ + ローパスフィルターの音を確認可能。Swift 実装時のリファレンスとして使用する。

## Out of Scope

- 画面フラッシュ（ペンディング）
- カスタム完了音（システムデフォルトのみ）
- 複数ノイズ種の選択 UI（Pink 固定）
- Campfire / 焚き火音（クオリティ不足でドロップ）
- バックグラウンドノイズ再生（Background Audio entitlement 不要）
- Watch / Widget でのノイズ再生
