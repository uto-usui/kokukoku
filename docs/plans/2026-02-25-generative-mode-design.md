# Generative Mode Design

## Goal

タイマー画面にリズムアニメーション表示を追加する。BPM 駆動の Pulse ビジュアルを実装し、Break 中の Decay 表現を含める。

## Background

STRATEGY.md Phase 2 に定義されたジェネラティブモード:
- タイマー画面をジェネラティブアートに切り替えるオプション（設定で ON/OFF）
- 残り時間は小さく数字で常時表示。図形は時間を「感じる」ための表現
- 技術: SwiftUI Canvas + TimelineView。Metal 不要の軽量実装

### Direction Change

当初は 4 種のジェネラティブアート（Subdivision / Lissajous / Grid Morphing / Breathing Rings）を段階実装する計画だったが、HTML モックアップでの検証を経て方針転換:

- Subdivision（曼荼羅）: 進行度に応じた図形の成長は「だんだん細かくなる」印象が主で、ジェネラティブアートとしての美しさに達しなかった
- **Pulse（心拍リズム）を採用**: 25 分間一貫して鼓動を感じる体験。集中状態の可視化として最も自然
- 4 種のビジュアル切り替えはペンディング。将来的に Protocol ベースで追加可能な設計は維持する

## Architecture

### File Structure

```
Features/Timer/Generative/
├── GenerativeVisual.swift       # Protocol + Factory + shared input type
├── PulseVisual.swift            # BPM駆動パーティクルフィールド
└── GenerativeTimerView.swift    # SwiftUI Canvas + TimelineView wrapper
```

### Protocol

```swift
struct GenerativeInput {
    let elapsed: TimeInterval       // session elapsed time in seconds
    let progress: Double            // 0.0 (start) → 1.0 (complete)
    let sessionType: SessionType
    let canvasSize: CGSize
}

protocol GenerativeVisual {
    func draw(in context: inout GraphicsContext, input: GenerativeInput)
}
```

`draw` はフレームごとに呼ばれる。`elapsed` でリズム位相を計算し、`progress` / `sessionType` でセッション表現を変える。

### Factory

```swift
enum GenerativeVisualFactory {
    static func visual() -> GenerativeVisual {
        PulseVisual()
    }
}
```

将来ビジュアル種を追加する場合、ここの switch を拡張する。

## Pulse Visual

BPM 60 の心拍リズムで粒子が明滅するパーティクルフィールド。

### Core Concept

- 心臓の鼓動（lub-dub）をダブルピークの Gaussian エンベロープで表現
- 中心から放射状にリップルが伝播し、通過した粒子が明滅する
- 粒子はブラウン運動でゆっくり漂う
- ダーク: 星空のような光点。ライト: 温かみのあるソフトな粒

### Confirmed Parameters (from mockup)

```
Rhythm:
  bpm           = 60
  sustain       = 2.5
  pulseScale    = 0.8
  rippleWidth   = 0.12
  rippleSpeed   = 1.4

Particles:
  count         = 63
  baseSize      = 1.0
  sizeRand      = 1.8
  baseAlpha     = 0.25
  pulseAlpha    = 0.50
  spread        = 0.81
  driftSpeed    = 0.31
  driftRange    = 0.07

Glow (Dark):
  softScale     = 1.00
  alphaScale    = 1.00
  innerR        = 0.25
  outerR        = 2.5
  midStop       = 0.40
  midAlpha      = 0.50
  centerGlow    = 0.06

Glow (Light):
  softScale     = 1.12
  alphaScale    = 0.70
  innerR        = 0.35
  outerR        = 1.7
  midStop       = 0.50
  midAlpha      = 0.30
  centerGlow    = 0.03
```

### Heartbeat Envelope

ダブルピーク Gaussian（lub-dub パターン）:
- 1st peak: position 0.08, sharp attack (width 0.035), sustain-scaled decay
- 2nd peak: position ~0.10–0.20, slightly wider attack, 0.45x amplitude
- Sustain パラメータで decay 幅を制御（光→暗の遷移速度）

### Ripple Propagation

- 心拍ごとに中心から円形の波が外側に伝播
- 各粒子は波が通過した瞬間に明滅（距離ベースの Gaussian 減衰）
- `rippleSpeed` / `rippleWidth` で伝播速度と波の幅を制御

### Particle Rendering

- 各粒子は `createRadialGradient` でソフトな円を描画
- テーマに応じて色・グロー・透明度が切り替わる
- ブラウン運動: ランダム加速 + 原点復帰力 + 速度減衰

### Break Expression (Decay)

Break セッション中は粒子の opacity を時間経過で下げる:
- `sessionAlpha = max(0.05, 1.0 - breakProgress * 0.8)`
- 完全には消えず、微かな存在感を残して Break 終了

## TimerScreen Integration

### Layout (Generative Mode ON)

```
[Session Label]           ← unchanged
┌─────────────────┐
│                  │
│   Canvas         │      ← replaces ProgressView
│   (pulse)        │
│                  │
│     12:34        │      ← timer digits smaller, overlaid on canvas
└─────────────────┘
[Cycle: 1/4]              ← unchanged
[Start/Pause]             ← unchanged
[Reset] [Skip]            ← unchanged
```

- `timerDisplay`: font size 74 → 32, overlaid at bottom of canvas
- `progressDisplay`: ProgressView → GenerativeTimerView
- Generative Mode OFF: 完全に既存のまま（変更なし）

### GenerativeTimerView

- `TimelineView(.animation)` でフレームレート更新
- `accessibilityReduceMotion` ON → Generative Mode 自動無効化、標準プログレスバーにフォールバック
- `aspectRatio(1, contentMode: .fit)` で正方形キャンバス
- `@Environment(\.colorScheme)` でテーマ検出、パラメータ切り替え

## Settings Integration

**UserTimerPreferences に追加:** `generativeModeEnabled: Bool` (default: false)

**TimerConfig に追加:** `generativeModeEnabled: Bool` (default: false)

**SettingsScreen:** "Appearance" セクションに Toggle 追加

**persistPreferences / applyPreferences** に読み書き追加。

## Testing Strategy

| Target | Test Content | Method |
|--------|-------------|--------|
| Heartbeat envelope | beatPhase → intensity, peak positions, sustain effect | Unit test (pure function) |
| Ripple intensity | distance + beatPhase → intensity | Unit test (pure function) |
| Decay opacity | breakProgress → sessionAlpha | Unit test |
| Particle init | count, spread → valid positions | Unit test |
| Settings persistence | generativeModeEnabled persists and applies | Unit test (existing pattern) |
| Visual rendering | Canvas renders without crash | Preview + manual |

Canvas 描画結果の自動テストは行わない。パラメータ計算の純粋関数テストで描画ロジックの正しさを間接保証。

## Accessibility

- `accessibilityReduceMotion` ON → Generative Mode 自動無効化、標準プログレスバーにフォールバック
- Canvas に `accessibilityLabel("Timer progress N%")` 付与
- VoiceOver: 既存テキスト表示が引き続き機能

## Mockup

`mockups/pulse.html` にパラメータ確定済みの HTML Canvas モックアップが存在する。全パラメータをスライダーで調整可能。Swift 実装時のリファレンスとして使用する。

## Future Extension (Pending)

以下は将来的な拡張として保留:
- Subdivision / Lissajous / Grid Morphing / Breathing Rings の追加
- ビジュアル種の選択 UI
- `GenerativeVisualFactory` の switch 拡張による切り替え
- Watch / Widget / MenuBar / Live Activity へのビジュアル表示
- Metal ハードウェアアクセラレーション
