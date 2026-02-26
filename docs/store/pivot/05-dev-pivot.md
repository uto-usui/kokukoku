# LP（ランディングページ）技術設計書

> 方針転換: 期間限定無料（約6ヶ月、KPI ベースで判断）→ 後に有料化（¥300 / $2.99）。LP を制作し、Web版タイマー + 支援動線 + App Store 導線 + 制作者紹介を統合する。

---

## 1. LP の技術スタック選定

### 1-1. 静的サイト vs フレームワーク

| 選択肢 | メリット | デメリット | 適合度 |
|--------|---------|-----------|--------|
| **素の HTML/CSS/JS** | ビルドステップ不要。依存ゼロ。デプロイが最速。ブランドの「無装飾」哲学と一致 | 多言語対応のルーティングが手動。コンポーネント再利用性が低い | 高 |
| **Astro** | 静的サイト生成に特化。JS ゼロの HTML 出力がデフォルト | 独自のファイルフォーマット（.astro）の学習コスト。React/Vue を使いたい場合は結局 JS island が必要 | 中 |
| **Next.js (Static Export)** | React エコシステム。`next export` で完全静的出力。標準的な React + TypeScript で開発可能。i18n ビルトイン | バンドルサイズは Astro より大きいが、Static Export なら許容範囲 | **最高** |
| **Hugo / 11ty** | 高速ビルド。Markdown ベースのコンテンツ管理 | テンプレート言語の癖。インタラクティブなタイマーの統合にはカスタム JS が必須 | 低 |

### 推奨: Next.js (Static Export)

**根拠:**

1. **Static Export**: `next export` で完全な静的 HTML/CSS/JS を出力。SSR サーバー不要でどこにでもデプロイ可能
2. **React エコシステム**: コンポーネントベースの開発。タイマー UI の状態管理が自然に書ける
3. **i18n 対応**: `next-intl` または Next.js のビルトイン i18n ルーティングで `/ja/` と `/en/` を宣言的に管理可能
4. **既存モックアップの活用**: `mockups/` にある HTML/CSS/JS は React コンポーネントとして自然に統合可能
5. **パフォーマンス**: Static Export + 適切な code splitting で Lighthouse 95+ が現実的
6. **開発者の馴染み**: 独自のファイルフォーマットやテンプレート構文を学ぶ必要がない。標準的な React + TypeScript で開発できる

**代替案（素の HTML/CSS/JS）が許容される条件:**

- ページ数が 5 以下で多言語対応を手動管理できる場合
- ビルドツールチェーンを一切入れたくない場合
- この場合、各言語版を個別の HTML ファイルとして管理する（`/privacy/index.html`、`/privacy/ja/index.html`）

### 1-2. ホスティング

| 選択肢 | 無料枠 | カスタムドメイン | HTTPS | CDN | ビルド | 適合度 |
|--------|--------|----------------|-------|-----|--------|--------|
| **GitHub Pages** | 無制限 | 対応 | 自動 | Fastly | GitHub Actions | 高 |
| **Cloudflare Pages** | 無制限 | 対応 | 自動 | Cloudflare | 自動ビルド | **最高** |
| **Vercel** | 100GB/月 | 対応 | 自動 | Vercel Edge | 自動ビルド | 高 |
| **Netlify** | 100GB/月 | 対応 | 自動 | Netlify Edge | 自動ビルド | 高 |

### 推奨: Cloudflare Pages（第一候補）、GitHub Pages（第二候補）

**Cloudflare Pages の根拠:**

1. **無制限の帯域**: 無料枠で帯域制限なし。バイラル時にも安心
2. **グローバル CDN**: 日本と北米の両方のターゲットユーザーに高速配信
3. **ビルド統合**: GitHub リポジトリとの自動連携。push でデプロイ
4. **Web Analytics（無料）**: プライバシーに配慮した軽量アナリティクスがビルトイン。Cookie 不要、JS スニペット 1 行追加のみ。Kokukoku の「Data Not Collected」方針と矛盾しない（Web サイトの訪問数のみでアプリとは無関係）
5. **カスタムドメイン + 自動 HTTPS**: 設定が最もシンプル

**GitHub Pages を第二候補とする理由:**

- 既存の `SUPPORT_STRATEGY.md` が `okiniirinoao.github.io/kokukoku/` を前提として設計済み
- App Store Connect に設定する URL が変わる。ただし独自ドメインを使えば同じ
- GitHub Actions でのデプロイは追加設定が必要
- 帯域制限が 100GB/月（通常の LP では十分だが、バイラル時にリスク）

### 1-3. ドメイン戦略

| 選択肢 | 例 | メリット | デメリット |
|--------|---|---------|-----------|
| **独自ドメイン** | `kokukoku.app` | ブランド想起、SEO、App Store URL の安定性 | 年間費用（.app は約 $14/年） |
| **github.io** | `okiniirinoao.github.io/kokukoku` | 無料、即時利用可能 | サブパス運用のため SEO 弱い。ブランド感に欠ける |
| **okiniirinoao.com + サブディレクトリ** | `okiniirinoao.com/kokukoku` | 制作者ポートフォリオと統合可能 | Kokukoku 固有のブランディングが薄れる |

### 推奨: `kokukoku.app` を取得

**根拠:**

1. `.app` TLD は Google 管理で HSTS 強制（HTTPS 必須）。セキュリティの信頼性が高い
2. App Store Connect の「サポート URL」「プライバシーポリシー URL」を独自ドメインで統一できる。ホスティング先を将来変更しても URL が不変
3. SEO: ルートドメインであることで検索エンジンの評価が高い
4. 年間約 $14 のコストは許容範囲
5. `kokukoku.app/privacy`、`kokukoku.app/support`、`kokukoku.app/timer` のようなクリーンな URL 構造
6. **CLI ベースのドメイン登録を推奨**: Cloudflare Wrangler（`wrangler`）、Gandi CLI（`gandi`）、または Namecheap CLI でドメイン取得・DNS 設定を完結させる。GUI ダッシュボードよりもスクリプト化・再現性に優れる

**URL 設計（確定版）:**

```
kokukoku.app/
├── /                       # LP トップ（Web タイマー + アプリ紹介）
├── /ja/                    # 日本語版トップ
├── /privacy/               # プライバシーポリシー（英語、デフォルト）
├── /ja/privacy/            # プライバシーポリシー（日本語）
├── /support/               # サポートページ（英語、デフォルト）
├── /ja/support/            # サポートページ（日本語）
└── /about/                 # 制作者紹介（okiniirinoao プロフィール）
```

---

## 2. Web版ポモドーロタイマーの技術設計

### 2-1. アプリのデザイン言語を CSS/JS で再現する

アプリの `TimerScreen.swift` を分析し、以下のビジュアル要素を Web に翻訳する。

#### Vibrant Material Surface

```css
/* SwiftUI の .ultraThinMaterial に相当 */
.timer-surface {
  background: rgba(255, 255, 255, 0.72);
  backdrop-filter: blur(24px) saturate(180%);
  -webkit-backdrop-filter: blur(24px) saturate(180%);
}

/* ダークモード */
@media (prefers-color-scheme: dark) {
  .timer-surface {
    background: rgba(28, 28, 30, 0.72);
  }
}
```

#### Grain Texture

アプリの `GrainOverlay` は 128x128 のノイズ `CGImage` をタイル状に並べている。Web では以下の2方式を検討する。

**方式 A: CSS + SVG フィルター（推奨）**

```css
.grain-overlay {
  position: fixed;
  inset: 0;
  pointer-events: none;
  opacity: 0.04;
  background-image: url("data:image/svg+xml,..."); /* インライン SVG ノイズ */
  /* または feTurbulence を利用 */
}

/* SVG filter を使う場合 */
.grain-overlay::before {
  content: '';
  position: absolute;
  inset: 0;
  filter: url(#grain-filter);
  opacity: 0.04;
}
```

```html
<svg width="0" height="0">
  <filter id="grain-filter">
    <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch" />
  </filter>
</svg>
```

**方式 B: Canvas で生成（アプリと同一アルゴリズム）**

```javascript
function generateGrainTexture() {
  const size = 128;
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const ctx = canvas.getContext('2d');
  const imageData = ctx.createImageData(size, size);
  for (let i = 0; i < size * size; i++) {
    const val = Math.random() * 255;
    imageData.data[i * 4] = val;
    imageData.data[i * 4 + 1] = val;
    imageData.data[i * 4 + 2] = val;
    imageData.data[i * 4 + 3] = 255;
  }
  ctx.putImageData(imageData, 0, 0);
  return canvas.toDataURL();
}
```

推奨は**方式 A**。SVG の `feTurbulence` は GPU アクセラレーションが効き、ページ読み込み時の JS 実行が不要。方式 B はアプリとのピクセル単位の一致が必要な場合のフォールバック。

#### 100pt Thin Weight Monospaceddigit タイマー数字

```css
.timer-digits {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', system-ui, sans-serif;
  font-size: clamp(60px, 15vw, 120px); /* レスポンシブ、最大 120px */
  font-weight: 100; /* thin */
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.02em;
  color: var(--fg);
  line-height: 1;
}
```

**注意:** `font-variant-numeric: tabular-nums` は数字の幅を固定し、カウントダウン時の桁ズレを防ぐ。これはアプリの `.monospacedDigit()` と同等。

Web 環境では SF Pro は macOS/iOS Safari でのみ利用可能。他の OS では system-ui にフォールバックするが、Inter（Google Fonts）を thin weight で読み込むことで品質を担保する。

```css
/* 非 Apple デバイス向けのフォールバック */
@supports not (-webkit-touch-callout: none) {
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@100&display=swap');
  .timer-digits {
    font-family: 'Inter', system-ui, sans-serif;
  }
}
```

#### Capsule ボタン

```css
.capsule-button {
  font-size: 1rem;
  font-weight: 500;
  padding: 12px 32px;
  border: none;
  border-radius: 9999px; /* capsule */
  background: var(--tertiary-bg);
  color: var(--fg);
  cursor: pointer;
  transition: opacity 0.15s ease;
}

.capsule-button:hover {
  opacity: 0.8;
}

.capsule-button:active {
  opacity: 0.6;
}
```

#### モノトーン運用

```css
:root {
  --bg: #ffffff;
  --fg: #1a1a1a;
  --fg-secondary: #888888;
  --fg-tertiary: #bbbbbb;
  --tertiary-bg: rgba(0, 0, 0, 0.06);
  --control-bg: #f5f5f5;
  --control-border: #e0e0e0;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0e0e0e;
    --fg: #e8e8e8;
    --fg-secondary: #666666;
    --fg-tertiary: #444444;
    --tertiary-bg: rgba(255, 255, 255, 0.10);
    --control-bg: #1a1a1a;
    --control-border: #333333;
  }
}
```

### 2-2. タイマーのコア機能

アプリの `TimerEngine` と同じ設計原則を Web に持ち込む: **endDate ベースのタイマーモデル**。

**Web 版タイマーの機能スコープ:**
- ポモドーロサイクル（Focus → Short Break → Long Break）
- Start / Pause / Reset / Skip 操作
- セッション種別とサイクル表示
- ピンクノイズ再生（オプション、Web Audio API）
- タブタイトルでの残り時間表示
- 完了音の再生
- 状態永続化なし（localStorage / Cookie は使用しない。ページリロードでリセット）

```javascript
// --- タイマーの時間モデル（アプリと同一原則） ---
// remaining = max(0, endDate - Date.now())
// elapsed-second counting は使わない

class PomodoroTimer {
  constructor() {
    this.state = 'idle';        // idle | running | paused
    this.sessionType = 'focus'; // focus | shortBreak | longBreak
    this.endDate = null;
    this.pausedRemaining = null;
    this.focusCount = 0;
    this.longBreakInterval = 4;

    // デフォルト時間（秒）
    this.durations = {
      focus: 25 * 60,
      shortBreak: 5 * 60,
      longBreak: 15 * 60,
    };
  }

  start() {
    if (this.state === 'idle') {
      const duration = this.durations[this.sessionType];
      this.endDate = Date.now() + duration * 1000;
      this.state = 'running';
    } else if (this.state === 'paused') {
      this.endDate = Date.now() + this.pausedRemaining;
      this.pausedRemaining = null;
      this.state = 'running';
    }
  }

  pause() {
    if (this.state !== 'running') return;
    this.pausedRemaining = Math.max(0, this.endDate - Date.now());
    this.endDate = null;
    this.state = 'paused';
  }

  reset() {
    this.state = 'idle';
    this.endDate = null;
    this.pausedRemaining = null;
    this.sessionType = 'focus';
    this.focusCount = 0;
  }

  skip() {
    this._advanceSession();
    this.state = 'idle';
    this.endDate = null;
    this.pausedRemaining = null;
  }

  get remaining() {
    if (this.state === 'running') {
      return Math.max(0, this.endDate - Date.now());
    }
    if (this.state === 'paused') {
      return this.pausedRemaining;
    }
    return this.durations[this.sessionType] * 1000;
  }

  get progress() {
    const total = this.durations[this.sessionType] * 1000;
    return 1 - this.remaining / total;
  }

  get isComplete() {
    return this.state === 'running' && this.remaining <= 0;
  }

  completeSession() {
    if (this.sessionType === 'focus') {
      this.focusCount++;
    }
    this._advanceSession();
    this.state = 'idle';
    this.endDate = null;
  }

  _advanceSession() {
    if (this.sessionType === 'focus') {
      this.sessionType =
        this.focusCount > 0 && this.focusCount % this.longBreakInterval === 0
          ? 'longBreak'
          : 'shortBreak';
    } else {
      this.sessionType = 'focus';
    }
  }
}
```

**タイマー描画ループ:**

```javascript
function renderLoop() {
  const remaining = timer.remaining;
  const minutes = Math.floor(remaining / 60000);
  const seconds = Math.floor((remaining % 60000) / 1000);
  timerDisplay.textContent =
    String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');

  if (timer.isComplete) {
    timer.completeSession();
    onSessionComplete();
  }

  requestAnimationFrame(renderLoop);
}
```

### 2-3. ナラティブビジュアルの統合

プロジェクトには 2 種類のビジュアルモックアップが存在する。

| モックアップ | ファイル | 概要 | LP での活用 |
|-------------|---------|------|------------|
| **Subdivision（曼荼羅）** | `mockups/subdivision.html` | 進捗に応じて曼荼羅が描画される。Focus 時は 0→100% で描画、Break 時は 100→0% で消えていく | **採用候補**: LP のヒーロービジュアルとして。ページ訪問者が最初に目にするインタラクティブ要素 |
| **Pulse（パーティクル）** | `mockups/pulse.html` | 心拍のようなパルスアニメーション。BPM に同期したパーティクルの拡散 | **背景演出候補**: タイマー動作中の背景として静かに脈動する |
| **Ambient Noise** | `mockups/ambient-noise.html` | Web Audio API によるピンクノイズ/ブラウンノイズ/焚き火音の生成 | **機能統合**: Web 版タイマーの付加機能として |

LP では以下の構成を推奨する。

1. ヒーローセクション: Subdivision 曼荼羅をカンバスの背景に配置。タイマーの進捗にリンクして描画が進む
2. タイマー実行中: Pulse パーティクルを `opacity: 0.15` 程度で背景に表示
3. アンビエントノイズ: オプション機能として、タイマー設定の一部として Web Audio API による環境音再生を提供

### 2-4. Web Audio API でアンビエントノイズを再生

**ピンクノイズは Web 版タイマーのスコープに含まれる（確定）。** タイマー動作中にオプションとして再生可能にする。

`mockups/ambient-noise.html` にピンクノイズ生成の実装が既にある。LP に統合する際の設計。

```javascript
// Web Audio API の初期化（ユーザージェスチャー後）
function initAudioContext() {
  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  const gain = ctx.createGain();
  gain.connect(ctx.destination);
  return { ctx, gain };
}

// ピンクノイズ生成（Voss-McCartney アルゴリズム、mockups/ambient-noise.html から移植）
function createPinkNoiseProcessor(ctx) {
  const bufferSize = 4096;
  const processor = ctx.createScriptProcessor(bufferSize, 1, 1);
  let runningSum = 0;
  const rows = new Float32Array(16);

  processor.onaudioprocess = (e) => {
    const output = e.outputBuffer.getChannelData(0);
    for (let i = 0; i < output.length; i++) {
      const white = Math.random() * 2 - 1;
      const row = Math.floor(Math.random() * 16);
      runningSum -= rows[row];
      rows[row] = white / 16;
      runningSum += rows[row];
      output[i] = (runningSum + white / 16) * 0.5;
    }
  };
  return processor;
}
```

**注意点:**

- `ScriptProcessorNode` は非推奨。可能であれば `AudioWorklet` に移行する。ただし Safari の AudioWorklet サポートは iOS 14.5+（2021年）以降なので、2026年時点では安全に使用可能
- ユーザージェスチャー（Start ボタンのクリック）後にのみ AudioContext を初期化する（ブラウザの自動再生ポリシー対応）
- フェードイン/フェードアウト: `gain.gain.linearRampToValueAtTime()` で滑らかに

### 2-5. セッション完了の通知

ブラウザの Notification API は**使用しない**。許可ダイアログがブランド体験を損ない、プラットフォームごとの挙動差が大きいため。代わりに以下の方法でセッション完了を知らせる:

1. **ブラウザタブのタイトル**: `00:00 - Session Complete` に変更。タブを切り替えていても気づける
2. **画面上のビジュアルフィードバック**: タイマー数字のパルスアニメーション
3. **完了音**: Web Audio API で短い（0.5秒）通知音を再生。ユーザーが Start を押した時点で AudioContext を初期化し、自動再生制約をクリア

### 2-6. レスポンシブ設計

```css
/* モバイルファースト */
.timer-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100svh; /* small viewport height（iOS Safari のアドレスバー考慮） */
  padding: 24px;
}

/* タブレット以上 */
@media (min-width: 768px) {
  .timer-container {
    max-width: 640px; /* アプリウィンドウと同じ最大幅 */
    margin: 0 auto;
  }
}

/* タイマー数字のレスポンシブサイズ */
.timer-digits {
  font-size: clamp(60px, 15vw, 120px);
}
```

**ブレークポイント:**

| 幅 | ターゲット | レイアウト |
|---|-----------|----------|
| < 480px | iPhone SE / コンパクト | タイマー数字 60px、ボタン幅 100% |
| 480-768px | iPhone Pro / iPad mini | タイマー数字 80px、ボタン幅 auto |
| 768px+ | iPad / デスクトップ | タイマー数字 120px、最大幅 640px で中央配置 |

### 2-7. パフォーマンス目標

| 指標 | 目標 |
|------|------|
| HTML + CSS + JS 合計 | < 100KB（gzip 前） |
| First Contentful Paint | < 1.0s |
| Largest Contentful Paint | < 1.5s |
| Total Blocking Time | < 50ms |
| Cumulative Layout Shift | 0 |
| Lighthouse Performance | 95+ |

**実現方法:**

- Next.js Static Export + dynamic import で、タイマーページのみクライアント JS を読み込む。他のページは静的 HTML
- Web フォントは Apple デバイスでは不要（system-ui = SF Pro）。非 Apple デバイスのみ Inter を条件付きで読み込む
- 画像は WebP + AVIF のダブルソース。App アイコンとスクリーンショットのみ
- CSS は 1 ファイルに統合。カスタムプロパティで全テーマを制御
- キャンバスアニメーション（Subdivision / Pulse）は `requestAnimationFrame` + `IntersectionObserver` で非可視時に停止

---

## 3. Patreon / 支援動線の技術的実装

### 3-1. プラットフォーム比較

| プラットフォーム | 手数料 | 日本円対応 | 特徴 | 適合度 |
|----------------|--------|-----------|------|--------|
| **Patreon** | 8-12% + 決済手数料 | 間接的（USD） | 月額サブスク型。継続支援に強い。認知度高い | 中 |
| **Ko-fi** | 0%（ゴールドは5%） | 対応 | 単発投げ銭が主。ショップ機能あり。手数料なしプランあり | **高** |
| **Buy Me a Coffee** | 5% | 対応 | UI がフレンドリー。月額メンバーシップも可能 | 高 |
| **GitHub Sponsors** | 0% | USD のみ | 開発者コミュニティとの親和性が高い。GitHub 経由の発見性 | 高（ペルソナA向け） |
| **OFUSE** | 10% | 日本円ネイティブ | 日本のクリエイター向け。ファンレター+投げ銭。日本のユーザーに馴染みがある | 中（ペルソナB/C向け） |
| **pixivFANBOX** | 10% | 日本円ネイティブ | 月額支援型。日本のクリエイターコミュニティで広く使われている | 中 |
| **note.com** | 15%（有料記事）/ 投げ銭は別 | 日本円ネイティブ | ブログ + 投げ銭（サポート機能）。開発ストーリー記事の発信と投げ銭を一体化できる。日本で広く認知されている | **高（ペルソナB/C向け）** |

### 3-2. 推奨構成

**メイン: Ko-fi（単発投げ銭）+ GitHub Sponsors（月額支援）**

**根拠:**

1. **Ko-fi**: 手数料 0%（無料プラン）。単発の「ありがとう」をローフリクションで受け付ける。LP 上にウィジェットを埋め込めるため、遷移なしで支援可能
2. **GitHub Sponsors**: ペルソナ A（ナレッジワーカー / エンジニア）が GitHub を日常的に使っている。月額支援と単発支援の両方に対応。手数料 0%
3. **日本向け（note.com）**: note.com で開発ストーリー記事を発信し、投げ銭（サポート）機能で支援を受け付ける。記事コンテンツそのものが集客にもなるため、ブログ + 支援の一石二鳥
4. **日本向けオプション**: OFUSE または pixivFANBOX を日本語ページにのみ追加リンクとして掲載

### 3-3. LP への統合方法

```html
<!-- Ko-fi ボタン（軽量、外部 JS 不要） -->
<a href="https://ko-fi.com/okiniirinoao"
   target="_blank"
   rel="noopener noreferrer"
   class="support-button">
  Support on Ko-fi
</a>

<!-- GitHub Sponsors リンク -->
<a href="https://github.com/sponsors/okiniirinoao"
   target="_blank"
   rel="noopener noreferrer"
   class="support-button">
  Sponsor on GitHub
</a>
```

**Ko-fi のウィジェット埋め込みは非推奨。** 外部 JS の読み込みはパフォーマンスとプライバシーの両方で LP のブランドに反する。シンプルなリンクボタンで十分。

### 3-4. 支援セクションの設計

LP 上の支援セクションは以下のトーンで設計する。

- ブランドボイスの「語りすぎない」原則を維持
- 「お金をください」ではなく「道具を長く維持するための支援」というフレーミング
- 支援ボタンは LP の下部に配置（タイマーとアプリ紹介の後）
- 支援額の提案は不要（Ko-fi / GitHub Sponsors のデフォルト UI に任せる）

```
JA: Kokukoku はひとりで作っています。気に入っていただけたら。
EN: Kokukoku is made by one person. If you find it useful.
```

---

## 4. App Store 連携

### 4-1. Smart App Banner

```html
<!-- iOS Safari で表示される Smart App Banner -->
<meta name="apple-itunes-app"
      content="app-id=YOUR_APP_ID, app-argument=kokukoku://">
```

**注意:** `app-id` は App Store Connect で発行される Apple ID（数値）。リリース前は空欄にしておき、ID 発行後に更新する。`app-argument` はユニバーサルリンク経由でアプリ内の特定画面に遷移させる場合に使用。

### 4-2. App Store バッジの配置

Apple の公式ガイドラインに従い、「Download on the App Store」バッジを使用する。

```html
<a href="https://apps.apple.com/app/kokukoku/idYOUR_APP_ID"
   target="_blank"
   rel="noopener noreferrer"
   class="app-store-badge">
  <img src="/images/app-store-badge.svg"
       alt="Download on the App Store"
       width="180" height="60"
       loading="lazy">
</a>

<!-- Mac App Store バッジ（別途） -->
<a href="https://apps.apple.com/app/kokukoku/idYOUR_APP_ID"
   target="_blank"
   rel="noopener noreferrer"
   class="mac-app-store-badge">
  <img src="/images/mac-app-store-badge.svg"
       alt="Download on the Mac App Store"
       width="180" height="60"
       loading="lazy">
</a>
```

**バッジの取得:** Apple Marketing Resources（`developer.apple.com/app-store/marketing/guidelines/`）から SVG 版をダウンロード。日本語版と英語版を `Accept-Language` に応じて切り替える。

### 4-3. バッジ配置の設計

| セクション | 配置 | 理由 |
|-----------|------|------|
| ヒーローセクション | タイマーの下、CTA として | Web タイマーを試した後に「アプリ版はもっと便利」の導線 |
| ページフッター | 常時表示 | どのページからもアプリへ導線を確保 |
| プライバシーポリシーページ | ページ下部 | Apple 審査チームが URL を確認する際に導線が見える |

### 4-4. ユニバーサルリンク

ユニバーサルリンクを設定することで、`kokukoku.app` のリンクをクリックした際にアプリが直接開く。

**1. apple-app-site-association ファイルの配置:**

```json
// kokukoku.app/.well-known/apple-app-site-association
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAM_ID.com.uto-usui.Kokukoku"],
        "components": [
          {
            "/": "/timer",
            "comment": "Open timer screen"
          },
          {
            "/": "/timer/*",
            "comment": "Timer deep links"
          }
        ]
      }
    ]
  },
  "webcredentials": {
    "apps": ["TEAM_ID.com.uto-usui.Kokukoku"]
  }
}
```

**2. Next.js での配置:**

```
public/
└── .well-known/
    └── apple-app-site-association  # JSON、拡張子なし
```

Cloudflare Pages / GitHub Pages はこのパスを自動的に `application/json` で配信する。

**3. Xcode 側の設定:**

- Capabilities → Associated Domains → `applinks:kokukoku.app`
- `webcredentials:kokukoku.app`

**初期バージョンではユニバーサルリンクは P2（推奨だが必須ではない）。** App Store URL（`apps.apple.com/...`）への直接リンクで十分機能する。

---

## 5. プライバシーポリシー / サポートページの統合

### 5-1. 既存コンテンツの Next.js への統合

`docs/appstore/` に以下のコンテンツが存在する。

| ファイル | 内容 | LP での配置 |
|---------|------|------------|
| `PRIVACY_POLICY_JA.md` | 日本語プライバシーポリシー | `/ja/privacy/` |
| `PRIVACY_POLICY_EN.md` | 英語プライバシーポリシー | `/privacy/` |
| `SUPPORT_STRATEGY.md` | サポートページの設計・FAQ 内容 | `/support/` と `/ja/support/` |

**Next.js での統合方法:**

```
src/
├── content/
│   ├── privacy/
│   │   ├── en.mdx         # PRIVACY_POLICY_EN.md の内容
│   │   └── ja.mdx         # PRIVACY_POLICY_JA.md の内容
│   └── support/
│       ├── en.mdx         # SUPPORT_STRATEGY.md の FAQ（英語部分）
│       └── ja.mdx         # SUPPORT_STRATEGY.md の FAQ（日本語部分）
├── components/
│   └── LegalLayout.tsx     # プライバシーポリシー/サポート用レイアウト
└── pages/
    ├── privacy.tsx         # 英語プライバシーポリシー
    ├── support.tsx         # 英語サポートページ
    └── ja/
        ├── privacy.tsx     # 日本語プライバシーポリシー
        └── support.tsx     # 日本語サポートページ
```

MDX ファイルは `@next/mdx` で直接インポートし、React コンポーネントとしてレンダリングする。

**LegalLayout の設計原則（SUPPORT_STRATEGY.md 準拠）:**

```css
.legal-content {
  max-width: 640px;    /* アプリウィンドウと同じ幅 */
  margin: 0 auto;
  padding: 48px 24px;
  font-family: system-ui, sans-serif;
  font-size: 15px;
  line-height: 1.7;
  color: #1a1a1a;
}

.legal-content h1 {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.legal-content h2 {
  font-size: 18px;
  font-weight: 600;
  margin-top: 32px;
  margin-bottom: 12px;
}
```

装飾なし。罫線・アイコン・イラストは使わない。ブランドボイスの「無装飾」原則を徹底する。

### 5-2. App Store Connect に設定する URL 構成

| フィールド | URL |
|-----------|-----|
| **サポート URL** | `https://kokukoku.app/support` |
| **プライバシーポリシー URL** | `https://kokukoku.app/privacy` |
| **マーケティング URL** | `https://kokukoku.app/` |

**言語自動切り替え:**

App Store Connect の各ローカライゼーション（日本語 / 英語）に対して個別の URL を設定可能。

| ローカライゼーション | サポート URL | プライバシーポリシー URL |
|---------------------|------------|----------------------|
| 日本語 | `https://kokukoku.app/ja/support` | `https://kokukoku.app/ja/privacy` |
| English | `https://kokukoku.app/support` | `https://kokukoku.app/privacy` |

### 5-3. プライバシーポリシーの更新

現在の `PRIVACY_POLICY_JA.md` には以下の更新が必要。

1. **課金セクション**: 「買い切り型の有料アプリ」→ 期間限定無料の場合は「無料でご利用いただけます。将来的に有料化する場合は、事前にお知らせいたします」に変更
2. **連絡先**: `[メールアドレスを記入]` → 実際のメールアドレス
3. **サポートページ URL**: `[サポートURLを記入]` → `https://kokukoku.app/support`

---

## 6. SEO 基本設定

### 6-1. メタタグ

```html
<!-- 共通 -->
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="canonical" href="https://kokukoku.app/">

<!-- 英語版 -->
<html lang="en">
<title>Kokukoku — Pomodoro Timer for Apple</title>
<meta name="description"
      content="A quiet Pomodoro timer for iPhone, Mac, and Apple Watch. No subscription. No clutter. Just focus.">

<!-- 日本語版 -->
<html lang="ja">
<title>Kokukoku — ポモドーロタイマー</title>
<meta name="description"
      content="iPhone、Mac、Apple Watch のためのポモドーロタイマー。買い切り。サブスクリプションなし。集中は、静けさの中にある。">
```

### 6-2. OGP（Open Graph Protocol）

```html
<!-- 共通 OGP -->
<meta property="og:type" content="website">
<meta property="og:site_name" content="Kokukoku">
<meta property="og:image" content="https://kokukoku.app/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">

<!-- 英語版 -->
<meta property="og:title" content="Kokukoku — Pomodoro Timer for Apple">
<meta property="og:description"
      content="A quiet Pomodoro timer for iPhone, Mac, and Apple Watch. One-time purchase.">
<meta property="og:url" content="https://kokukoku.app/">
<meta property="og:locale" content="en_US">
<meta property="og:locale:alternate" content="ja_JP">

<!-- 日本語版 -->
<meta property="og:title" content="Kokukoku — ポモドーロタイマー">
<meta property="og:description"
      content="iPhone、Mac、Apple Watch のためのポモドーロタイマー。買い切り、サブスクなし。">
<meta property="og:url" content="https://kokukoku.app/ja/">
<meta property="og:locale" content="ja_JP">
<meta property="og:locale:alternate" content="en_US">

<!-- Twitter Card -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:site" content="@okiniirinoao">
<meta name="twitter:creator" content="@okiniirinoao">
```

**OGP 画像の設計:**

- サイズ: 1200 x 630px
- 内容: 白背景に `25:00` のタイマー数字 + 「Kokukoku」ロゴ + タグライン
- アプリのスクリーンショット SS1 のビジュアルを流用し、横長にクロップ
- テキストは大きく。SNS のタイムラインで縮小表示されても読めるサイズ

### 6-3. 構造化データ（JSON-LD）

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Kokukoku",
  "operatingSystem": "iOS, macOS, watchOS",
  "applicationCategory": "ProductivityApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "JPY",
    "availability": "https://schema.org/InStock"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "ratingCount": "0"
  },
  "author": {
    "@type": "Person",
    "name": "okiniirinoao",
    "url": "https://kokukoku.app/about"
  },
  "description": "A quiet Pomodoro timer for iPhone, Mac, and Apple Watch.",
  "url": "https://kokukoku.app/",
  "downloadUrl": "https://apps.apple.com/app/kokukoku/idYOUR_APP_ID",
  "screenshot": "https://kokukoku.app/images/og-image.png"
}
</script>
```

**注意:**

- `price` は期間限定無料の間は `"0"` に設定。有料化後に `"300"`（¥300 / $2.99）に更新
- `aggregateRating` はリリース後にレビューが集まってから追加。リリース前は省略
- `downloadUrl` は App Store ID 確定後に設定

### 6-4. 多言語対応（hreflang）

```html
<!-- 英語ページ -->
<link rel="alternate" hreflang="en" href="https://kokukoku.app/">
<link rel="alternate" hreflang="ja" href="https://kokukoku.app/ja/">
<link rel="alternate" hreflang="x-default" href="https://kokukoku.app/">

<!-- 日本語ページ -->
<link rel="alternate" hreflang="en" href="https://kokukoku.app/">
<link rel="alternate" hreflang="ja" href="https://kokukoku.app/ja/">
<link rel="alternate" hreflang="x-default" href="https://kokukoku.app/">
```

### 6-5. sitemap.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>https://kokukoku.app/</loc>
    <xhtml:link rel="alternate" hreflang="ja" href="https://kokukoku.app/ja/"/>
    <xhtml:link rel="alternate" hreflang="en" href="https://kokukoku.app/"/>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://kokukoku.app/privacy</loc>
    <xhtml:link rel="alternate" hreflang="ja" href="https://kokukoku.app/ja/privacy"/>
    <xhtml:link rel="alternate" hreflang="en" href="https://kokukoku.app/privacy"/>
    <changefreq>yearly</changefreq>
    <priority>0.5</priority>
  </url>
  <url>
    <loc>https://kokukoku.app/support</loc>
    <xhtml:link rel="alternate" hreflang="ja" href="https://kokukoku.app/ja/support"/>
    <xhtml:link rel="alternate" hreflang="en" href="https://kokukoku.app/support"/>
    <changefreq>monthly</changefreq>
    <priority>0.5</priority>
  </url>
</urlset>
```

Next.js では `next-sitemap` パッケージで Static Export 後に自動生成可能。

### 6-6. robots.txt

```
User-agent: *
Allow: /
Sitemap: https://kokukoku.app/sitemap-index.xml
```

### 6-7. favicon

```html
<link rel="icon" type="image/svg+xml" href="/favicon.svg">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">
<link rel="manifest" href="/site.webmanifest">
<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0e0e0e" media="(prefers-color-scheme: dark)">
```

アプリアイコンの Tinted バリアント（モノクロ）を favicon として使用する。

---

## 付録 A: LP のページ構成と情報アーキテクチャ

```
kokukoku.app/
│
├── [ヒーローセクション]
│   ├── Kokukoku ロゴ / タイトル
│   ├── タグライン: 「時を刻む、ただそれだけ。」
│   ├── Web版ポモドーロタイマー（インタラクティブ）
│   │   ├── タイマー数字（100pt thin weight）
│   │   ├── セッション種別ラベル（Focus / Short Break / Long Break）
│   │   ├── サイクル表示（1/4）
│   │   ├── Start / Pause ボタン（capsule）
│   │   ├── Reset / Skip ボタン
│   │   └── [オプション] アンビエントノイズ トグル
│   └── 背景: Subdivision 曼荼羅 or Pulse パーティクル
│
├── [アプリ紹介セクション]
│   ├── スクリーンショット（SS1-SS3 を流用）
│   ├── 機能ハイライト（3カラム）
│   │   ├── Apple Watch + iPhone + Mac
│   │   ├── Live Activity / Dynamic Island
│   │   └── データ収集なし / 買い切り
│   ├── App Store バッジ（iOS + macOS）
│   └── Smart App Banner（iOS Safari 自動表示）
│
├── [制作者セクション]
│   ├── okiniirinoao プロフィール
│   ├── SNS リンク（X, GitHub）
│   └── 「Kokukoku はひとりで作っています。」
│
├── [支援セクション]
│   ├── Ko-fi リンク
│   ├── GitHub Sponsors リンク
│   ├── [日本語のみ] note.com 開発ストーリー + 投げ銭リンク
│   └── [日本語のみ] OFUSE / pixivFANBOX リンク
│
└── [フッター]
    ├── プライバシーポリシー（/privacy）
    ├── サポート（/support）
    ├── App Store バッジ
    └── (c) 2026 okiniirinoao
```

---

## 付録 B: 実装優先度

| 優先度 | タスク | 工数目安 | ブロッカー |
|--------|--------|---------|-----------|
| **P0** | ドメイン `kokukoku.app` 取得 | 30分 | なし |
| **P0** | Next.js プロジェクト初期化 + Cloudflare Pages 接続 | 2時間 | ドメイン取得 |
| **P0** | プライバシーポリシーページ（日英）のデプロイ | 1時間 | Next.js 初期化 |
| **P0** | サポートページ（FAQ + 連絡先）のデプロイ | 1時間 | Next.js 初期化 |
| **P1** | Web版ポモドーロタイマーの実装 | 8時間 | なし |
| **P1** | デザイン言語の CSS 翻訳（grain, material, typography） | 4時間 | なし |
| **P1** | App Store バッジ + Smart App Banner の設置 | 30分 | App Store ID |
| **P1** | OGP 画像の制作 | 2時間 | なし |
| **P2** | ナラティブビジュアル（Subdivision / Pulse）の統合 | 4時間 | Web タイマー |
| **P2** | アンビエントノイズ機能の統合 | 3時間 | Web タイマー |
| **P2** | 制作者紹介ページ | 2時間 | なし |
| **P2** | 支援動線（Ko-fi + GitHub Sponsors）の設置 | 1時間 | アカウント作成 |
| **P2** | SEO 基本設定（構造化データ、sitemap、robots.txt） | 1時間 | デプロイ後 |
| **P3** | ユニバーサルリンク設定 | 2時間 | App Store ID + Xcode 設定 |
| **P3** | PWA 化（Service Worker、オフラインタイマー） | 4時間 | Web タイマー |
| **P3** | Web Push Notification（Service Worker 経由） | 3時間 | PWA 化 |

---

## 付録 C: ディレクトリ構成（Next.js プロジェクト）

```
web/
├── next.config.mjs
├── package.json
├── tsconfig.json
├── public/
│   ├── .well-known/
│   │   └── apple-app-site-association
│   ├── favicon.svg
│   ├── favicon-32.png
│   ├── favicon-192.png
│   ├── apple-touch-icon.png
│   ├── site.webmanifest
│   ├── robots.txt
│   └── images/
│       ├── og-image.png
│       ├── og-image-ja.png
│       ├── app-store-badge.svg
│       ├── app-store-badge-ja.svg
│       └── screenshots/
│           ├── ss1-hero.webp
│           ├── ss2-running.webp
│           └── ss3-break.webp
├── src/
│   ├── components/
│   │   ├── Timer.tsx              # タイマー（'use client' コンポーネント）
│   │   ├── TimerEngine.ts         # PomodoroTimer クラス
│   │   ├── GrainOverlay.tsx       # SVG ノイズテクスチャ
│   │   ├── NarrativeCanvas.tsx    # Subdivision / Pulse ビジュアル（'use client'）
│   │   ├── AmbientNoise.ts        # Web Audio API ノイズ生成
│   │   ├── AppStoreBadge.tsx      # App Store バッジコンポーネント
│   │   ├── SupportButton.tsx      # Ko-fi / GitHub Sponsors リンク
│   │   └── Footer.tsx
│   ├── content/
│   │   ├── privacy/
│   │   │   ├── en.mdx
│   │   │   └── ja.mdx
│   │   └── support/
│   │       ├── en.mdx
│   │       └── ja.mdx
│   ├── i18n/
│   │   ├── en.json                # UI 文字列（英語）
│   │   └── ja.json                # UI 文字列（日本語）
│   ├── layouts/
│   │   ├── BaseLayout.tsx         # 共通レイアウト（head, OGP, footer）
│   │   └── LegalLayout.tsx        # プライバシーポリシー/サポート用
│   ├── pages/
│   │   ├── _app.tsx               # カスタム App（グローバル CSS 読み込み）
│   │   ├── _document.tsx          # カスタム Document（lang 属性、OGP）
│   │   ├── index.tsx              # 英語 LP
│   │   ├── privacy.tsx
│   │   ├── support.tsx
│   │   ├── about.tsx
│   │   └── ja/
│   │       ├── index.tsx          # 日本語 LP
│   │       ├── privacy.tsx
│   │       └── support.tsx
│   └── styles/
│       └── global.css             # CSS カスタムプロパティ + 全スタイル
└── .github/
    └── workflows/
        └── deploy.yml             # Cloudflare Pages デプロイ
```

---

## 付録 D: 技術的判断の根拠まとめ

| 判断 | 選定 | 根拠 |
|------|------|------|
| フレームワーク | Next.js (Static Export) | React エコシステム + 静的出力。タイマーのみ `'use client'` で JS を読み込む |
| ホスティング | Cloudflare Pages | 無制限帯域、グローバル CDN、無料アナリティクス |
| ドメイン | kokukoku.app | HSTS 強制、ブランド想起、URL 安定性 |
| 支援プラットフォーム | Ko-fi + GitHub Sponsors + note.com（日本向け） | 手数料 0%（Ko-fi/GH）、note.com は開発ストーリー発信+投げ銭の一体運用 |
| CSS 設計 | カスタムプロパティ + system-ui | アプリと同一のデザイントークン。Web フォント最小化 |
| タイマーモデル | endDate ベース | アプリの TimerEngine と同一原則。タブ非アクティブでも正確 |
| OGP 画像 | SS1 ヒーローショット流用 | 既存アセットの再利用。追加コスト最小 |
| ナラティブビジュアル | 既存モックアップ移植 | `mockups/subdivision.html`、`mockups/pulse.html` をそのまま統合可能 |
