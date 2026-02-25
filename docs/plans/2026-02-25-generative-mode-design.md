# Generative Mode Phase 1 Design

## Goal

タイマー画面にジェネラティブアート表示を追加する。Phase 1 では Session 1「円の分割 (Subdivision)」のみ実装し、Break 中の Decay 表現を含める。アーキテクチャを確立し、後続の 3 ビジュアル追加を容易にする。

## Background

STRATEGY.md Phase 2 に定義されたジェネラティブモード:
- タイマー画面をジェネラティブアートに切り替えるオプション（設定で ON/OFF）
- 残り時間は小さく数字で常時表示。図形は時間を「感じる」ための表現
- 入力パラメータは「残り時間」「セッション種別」「セッション番号」のみ。決定論的
- 技術: SwiftUI Canvas + TimelineView。Metal 不要の軽量実装

Phase 1 スコープ: Subdivision ビジュアル 1 種 + Decay + Settings toggle + アーキテクチャ基盤

## Architecture

### File Structure

```
Features/Timer/Generative/
├── GenerativeVisual.swift       # Protocol + Factory + shared input type
├── SubdivisionVisual.swift      # Session 1: 円の分割
├── DecayModifier.swift          # Break中のフェードアウト計算
└── GenerativeTimerView.swift    # SwiftUI Canvas + TimelineView wrapper
```

### Protocol

```swift
struct GenerativeInput {
    let progress: Double        // 0.0 (start) → 1.0 (complete)
    let sessionType: SessionType
    let sessionIndex: Int       // completedFocusCount % longBreakFrequency
    let canvasSize: CGSize
}

protocol GenerativeVisual {
    func draw(in context: inout GraphicsContext, input: GenerativeInput)
}
```

`draw` は純粋関数。同じ input に対して同じ描画を返す（決定論的）。

### Factory

```swift
enum GenerativeVisualFactory {
    static func visual(for sessionIndex: Int) -> GenerativeVisual {
        // Phase 1: always returns Subdivision
        SubdivisionVisual()
    }
}
```

Phase 2 で sessionIndex に基づくビジュアル切り替えをここに追加。

## Subdivision Visual

25 分間で 1 つの円が幾何学的な曼荼羅に成長する。

### Parameter Mapping (progress → drawing)

| progress | concentricRings | radialDivisions | arcDetail | strokeOpacity |
|----------|----------------|-----------------|-----------|---------------|
| 0.0      | 1              | 0               | 0.0       | 0.3           |
| 0.25     | 2              | 3               | 0.0       | 0.45          |
| 0.50     | 4              | 6               | 0.0       | 0.6           |
| 0.75     | 6              | 12              | 0.5       | 0.8           |
| 1.0      | 8              | 24              | 1.0       | 1.0           |

### Drawing Steps

1. 外周円を描画
2. progress に応じて同心円を内側に追加（等間隔）
3. progress に応じて中心から放射状の線を追加
4. progress 0.5 以降: 同心円と放射線の交点間をアーク（円弧）で接続 → 曼荼羅パターン出現
5. progress 1.0 で結晶的な完成形

### Style

- `.primary` モノクロ（ライト/ダークモード両対応）
- 線幅: Canvas サイズ相対（`size.width * 0.003` 程度）
- Fill なし、stroke のみ

## Decay (Break Expression)

Break セッション中は完成した図形がフェードアウトする:

- Break progress 0.0 (直後): 完成形を opacity 1.0 で表示
- Break progress 1.0 (終了): opacity 0.0 で消滅
- 実装: Subdivision を progress=1.0 で描画 + `opacity(1.0 - breakProgress)` 適用

```swift
struct DecayModifier {
    static func opacity(breakProgress: Double) -> Double {
        max(0, 1.0 - breakProgress)
    }
}
```

## TimerScreen Integration

### Layout (Generative Mode ON)

```
[Session Label]           ← unchanged
┌─────────────────┐
│                  │
│   Canvas         │      ← replaces ProgressView
│   (generative)   │
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

- `TimelineView(.periodic(every: 0.1))` で 10fps 更新
- `accessibilityReduceMotion` ON → `TimelineView(.everyMinute)` にフォールバック
- `aspectRatio(1, contentMode: .fit)` で正方形キャンバス

## Settings Integration

**UserTimerPreferences に追加:** `generativeModeEnabled: Bool` (default: false)

**TimerConfig に追加:** `generativeModeEnabled: Bool` (default: false)

**SettingsScreen:** "Appearance" セクションに Toggle 追加

**persistPreferences / applyPreferences** に読み書き追加。

## Testing Strategy

| Target | Test Content | Method |
|--------|-------------|--------|
| Subdivision parameter calc | progress 0/0.25/0.5/0.75/1.0 → correct rings/divisions/opacity | Unit test (pure function) |
| DecayModifier.opacity | breakProgress → opacity conversion | Unit test |
| GenerativeVisualFactory | sessionIndex → correct visual type | Unit test |
| Settings persistence | generativeModeEnabled persists and applies | Unit test (existing pattern) |
| Visual rendering | Canvas renders without crash | Preview + manual |

Canvas 描画結果の自動テストは行わない（コスト対効果が低い）。パラメータ計算の純粋関数テストで描画ロジックの正しさを間接保証。

## Accessibility

- `accessibilityReduceMotion` ON → Generative Mode 自動無効化、標準プログレスバーにフォールバック
- Canvas に `accessibilityLabel("Timer progress N%")` 付与
- VoiceOver: 既存テキスト表示が引き続き機能

## Mockup Strategy

Swift 実装前に HTML Canvas でモックアップを作成し、ビジュアルの方向性を検証する:

- HTML Canvas と SwiftUI Canvas は描画プリミティブ（arc, line, path, stroke）が類似
- progress スライダーで 0→1 の進行を操作して確認
- Decay のフェードアウト確認
- ライト/ダークモード切り替え
- パラメータ確定後、数学ロジックをそのまま Swift に移植

## Phase 2 Extension Path

1. `LissajousVisual`, `GridMorphingVisual`, `BreathingRingsVisual` を protocol 準拠で追加
2. `GenerativeVisualFactory.visual(for:)` の switch を拡張
3. 他のコード変更不要

## Out of Scope (Phase 1)

- Watch / Widget / MenuBar / Live Activity へのジェネラティブ表示
- ビジュアルの種類選択 UI（Phase 1 は Subdivision 固定）
- Metal ハードウェアアクセラレーション
