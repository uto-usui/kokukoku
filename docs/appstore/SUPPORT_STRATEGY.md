# サポート体制の提案

App Store には「サポート URL」の入力が必須です。ここでは選択肢と推奨を整理します。

## トーンとブランドボイス

サポートページは Kokukoku ブランドの一部である。CDO が定義したブランドボイス（**静謐・端正・余白的・無装飾・凛とした**）はサポート文面にも適用する。

**原則:**
- 簡潔に、必要なことだけを伝える。冗長な説明や過剰な謝意は避ける
- 主語は「Kokukoku」か「あなた」。一人称（「私たち」「弊社」）を極力使わない
- 感嘆符は使わない。絵文字は使わない
- 技術的に正確であることを最優先しつつ、専門用語を押し付けない
- 英語版も同じ静かなトーンを維持する。"We're sorry for the inconvenience!" のような定型句は不要

---

## 選択肢の比較

### 選択肢 1: GitHub Issues（推奨）

| 項目 | 内容 |
|---|---|
| URL 例 | `https://github.com/okiniirinoao/kokukoku/issues` |
| コスト | 無料 |
| セットアップ | リポジトリを public にして Issue テンプレートを用意するだけ |
| メリット | バグ報告と機能要望を構造化できる。開発ワークフローと統合。Markdown 対応 |
| デメリット | GitHub アカウントが必要（一部ユーザーにはハードル）。技術者向けの印象 |
| 適合度 | ターゲットユーザー（ナレッジワーカー、デザイナー）には馴染みがある |

#### Issue テンプレート案

リポジトリに `.github/ISSUE_TEMPLATE/` を作成し、以下のテンプレートを用意:

- `bug_report.md` -- バグ報告用
- `feature_request.md` -- 機能要望用

### 選択肢 2: 専用メールアドレス

| 項目 | 内容 |
|---|---|
| URL 例 | `mailto:support@example.com`（App Store Connect ではメールアドレスのみ入力可能な場合あり） |
| コスト | メールアドレスの取得コスト（独自ドメインの場合） |
| メリット | 誰でもメールは送れる。GitHub アカウント不要 |
| デメリット | 管理が煩雑。スパム対策が必要。構造化されていない |
| 適合度 | 非技術者ユーザーや、GitHub を使わない学生層へのフォールバック |

### 選択肢 3: 静的サポートページ（GitHub Pages）

| 項目 | 内容 |
|---|---|
| URL 例 | `https://okiniirinoao.github.io/kokukoku/support` |
| コスト | 無料 |
| メリット | FAQ を掲載できる。プライバシーポリシーも同じサイトに掲載可能。ブランドに沿ったデザインが可能 |
| デメリット | サイトの構築・維持が必要 |
| 適合度 | プライバシーポリシーのホスティング先としても兼用でき効率的 |

### 選択肢 4: X (Twitter) / SNS アカウント

| 項目 | 内容 |
|---|---|
| URL 例 | `https://x.com/okiniirinoao` |
| コスト | 無料 |
| メリット | ユーザーとの距離が近い。アップデート情報の発信にも使える |
| デメリット | サポートの体系化が難しい。Apple が正式なサポート手段として認めない可能性 |
| 適合度 | メインのサポート手段としては非推奨。補助的に使用 |

---

## 推奨構成

**GitHub Pages + GitHub Issues + メールアドレスの組み合わせ**を推奨。

### 構成イメージ

```
https://okiniirinoao.github.io/kokukoku/
├── index.html          # アプリ紹介ページ（任意）
├── privacy/            # プライバシーポリシー（日英）
│   ├── index.html      # 英語版（デフォルト）
│   └── ja.html         # 日本語版
└── support/            # サポートページ
    └── index.html      # FAQ + 連絡先
```

### サポートページのデザイン方針

GitHub Pages で構築するサポートページは、Kokukoku のブランドと一貫した外観にする。

| 要素 | 仕様 |
|------|------|
| 背景色 | `#FFFFFF` |
| テキスト色 | `#1A1A1A` |
| 書体 | system-ui（OS 標準フォント）。macOS/iOS では SF Pro が適用される |
| 最大幅 | 640px（アプリウィンドウと同じ幅） |
| 装飾 | なし。罫線・アイコン・イラストは使わない |
| レスポンシブ | モバイルファースト。iPhone の Safari で読みやすいこと |

---

### FAQ の内容とトーン

FAQ は簡潔に、問いと答えだけを記す。前置きや謝辞は不要。

#### 日本語 FAQ

**Q: タイマーがバックグラウンドで止まりませんか。**
A: Kokukoku は終了予定時刻を基準にタイマーを管理しています。アプリがバックグラウンドにあっても、復帰時に正しい残り時間が表示されます。セッション完了の通知はバックグラウンドでも届きます。

**Q: Apple Watch と接続できません。**
A: iPhone と Apple Watch が同じ iCloud アカウントでペアリングされていることを確認してください。両方のデバイスで Kokukoku が最新バージョンであることもご確認ください。

**Q: 通知が届きません。**
A: 「設定」>「通知」>「Kokukoku」で通知が有効になっていることを確認してください。集中モードが有効な場合、通知が抑制されることがあります。

**Q: ピンクノイズが再生されません。**
A: 設定画面で「環境音」が有効になっていることを確認してください。デバイスのサイレントモードが解除されていること、音量が十分であることもご確認ください。

**Q: macOS のメニューバーにアイコンが表示されません。**
A: システム設定の「コントロールセンター」でメニューバーのアイテム表示を確認してください。Kokukoku が起動中であることが前提です。

**Q: データを別のデバイスに移行できますか。**
A: セッション履歴と設定はデバイス上にローカル保存されます。デバイス間のクラウド同期には対応していません。iPhone と Apple Watch の間ではタイマーの状態がリアルタイムで同期されます。

#### 英語 FAQ

**Q: Does the timer stop in the background?**
A: Kokukoku calculates remaining time from a target end date, not elapsed seconds. When you return to the app, the correct remaining time is displayed. Session completion notifications are delivered even while the app is in the background.

**Q: I can't connect to my Apple Watch.**
A: Confirm that your iPhone and Apple Watch are paired under the same iCloud account. Ensure both devices have the latest version of Kokukoku installed.

**Q: I'm not receiving notifications.**
A: Check that notifications are enabled in Settings > Notifications > Kokukoku. If Focus Mode is active, notifications may be suppressed.

**Q: Pink noise doesn't play.**
A: Confirm that "Ambient Noise" is enabled in the Settings screen. Ensure Silent Mode is off and the volume is audible.

**Q: The menu bar icon doesn't appear on macOS.**
A: Kokukoku must be running for the menu bar item to appear. Check System Settings > Control Center for menu bar item visibility.

**Q: Can I transfer my data to another device?**
A: Session history and settings are stored locally on each device. Cloud sync between devices is not supported. Timer state syncs in real time between iPhone and Apple Watch.

---

### バグ報告・機能要望

GitHub Issues へのリンク: `https://github.com/okiniirinoao/kokukoku/issues`

サポートページには以下のように記載:

> **日本語:** 不具合の報告や機能のご要望は GitHub Issues からお送りください。GitHub アカウントをお持ちでない場合は、メールでもお受けしています。
>
> **英語:** Report issues or request features on GitHub Issues. If you don't have a GitHub account, email is also available.

### メールでのお問い合わせ

- `support@example.com`（確定後に差し替え）

サポートページには以下のように記載:

> **日本語:** [メールアドレス]
>
> **英語:** [メールアドレス]

メールアドレスのみ。「お気軽にお問い合わせください」等の定型句は不要。

---

## App Store Connect への入力

| フィールド | 入力値 |
|---|---|
| サポート URL | `https://okiniirinoao.github.io/kokukoku/support` |
| プライバシーポリシー URL | `https://okiniirinoao.github.io/kokukoku/privacy` |
| マーケティング URL（任意） | `https://okiniirinoao.github.io/kokukoku/` |

---

## 推奨の理由

1. **コスト**: すべて無料で運用可能
2. **メンテナンス**: GitHub Pages は Markdown から自動ビルドでき、維持コストが低い
3. **一元管理**: プライバシーポリシー、サポート、アプリ紹介をすべて同じリポジトリ/サイトで管理
4. **信頼性**: GitHub の稼働率は高く、Apple の審査チームからも安定してアクセス可能
5. **Apple 審査対応**: 正式な URL として審査に問題なし
6. **ブランド一貫性**: 静的サイトなので、Kokukoku のビジュアルアイデンティティ（白背景、ミニマル、SF Pro）を完全に制御できる

---

## 実装優先度

| 優先度 | タスク | 必須/推奨 |
|---|---|---|
| P0 | プライバシーポリシーページの公開（日英） | **必須**（App Store 審査要件） |
| P0 | サポートページの公開（FAQ + 連絡先） | **必須**（App Store 審査要件） |
| P0 | サポート用メールアドレスの取得 | **必須** |
| P1 | GitHub Issues のテンプレート整備 | 推奨 |
| P1 | サポートページのブランドデザイン適用 | 推奨（初回はプレーンでも可） |
| P2 | FAQ の充実（リリース後にユーザーからの問い合わせを反映） | 推奨 |
| P3 | アプリ紹介ページの作成 | 任意 |
