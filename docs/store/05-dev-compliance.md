# Kokukoku Dev / コンプライアンス

App Store 審査・公開に必要な技術メタデータとコンプライアンス文書。

各ドキュメントの詳細は `docs/appstore/` を参照。

## ドキュメント一覧

| ファイル | 内容 |
|---------|------|
| [`PRIVACY_POLICY_JA.md`](../appstore/PRIVACY_POLICY_JA.md) | プライバシーポリシー（日本語）。データ収集なし、完全オフライン動作。個人情報保護法対応 |
| [`PRIVACY_POLICY_EN.md`](../appstore/PRIVACY_POLICY_EN.md) | プライバシーポリシー（英語）。GDPR / CCPA セクション含む |
| [`APP_PRIVACY_GUIDE.md`](../appstore/APP_PRIVACY_GUIDE.md) | App Store Connect「App Privacy」の回答ガイド。「Data Not Collected」選択手順 |
| [`REVIEW_NOTES.md`](../appstore/REVIEW_NOTES.md) | 審査メモ。ログイン不要、AVAudioEngine使用理由、テスト手順、Apple Watch テスト手順 |
| [`AGE_RATING_GUIDE.md`](../appstore/AGE_RATING_GUIDE.md) | 年齢レーティング回答ガイド。目標: 4+ |
| [`TECHNICAL_METADATA.md`](../appstore/TECHNICAL_METADATA.md) | Bundle ID、最小OS、フレームワーク一覧、暗号化、カテゴリ、価格、スクリーンショット解像度 |
| [`SUPPORT_STRATEGY.md`](../appstore/SUPPORT_STRATEGY.md) | サポート体制の提案。GitHub Pages + Issues + メール推奨。ブランドボイスに準拠したトーン |

---

## 他チームとの連携ポイント

### プロダクトプランナー (01) との連携

| 観点 | 影響 | 対応状況 |
|------|------|----------|
| **ソフトローンチ（日本先行 → グローバル）** | 審査メモでローンチ対象地域を意識した記述が必要。初回は日本リージョンのみ公開 → App Store Connect の「Pricing and Availability」で地域を日本のみに設定し、グローバル展開時に全リージョンへ拡大。審査メモ自体は英語で記述し、グローバル展開後もそのまま使える内容にする | REVIEW_NOTES.md に反映済み |
| **ユニバーサル購入の訴求** | プライバシーポリシー・審査メモに「iOS + macOS + watchOS」のユニバーサル購入を明記。マーケティングコピーの「1回の購入ですべてのAppleデバイスに」と整合させる | REVIEW_NOTES.md, TECHNICAL_METADATA.md に反映済み |
| **Apple Watch 双方向同期** | WatchConnectivity の通信がデバイス間直接通信であることをプライバシーポリシーに明記（外部サーバー非経由）。審査メモに Watch アプリのテスト手順を追加 | PRIVACY_POLICY_JA/EN, REVIEW_NOTES.md に反映済み |

### マーケティング (02) との連携

| 観点 | 影響 | 対応状況 |
|------|------|----------|
| **「データ収集なし」の訴求** | マーケティングコピーが「No analytics, no ads, no data collection」を強調。App Privacy の「Data Not Collected」ラベルと完全に整合。プライバシーポリシーの「一切収集しません」表現とも一致 | 整合性確認済み。齟齬なし |
| **「サブスクリプションなし。買い切り」** | プライバシーポリシーの「課金」セクションに「買い切り型。アプリ内課金・サブスクリプションなし」を明記済み | 整合性確認済み。齟齬なし |
| **「アンビエントピンクノイズ」の機能訴求** | コピーが「ピンクノイズ」を特徴として訴求 → 審査メモで AVAudioEngine の再生専用使用を明確に説明し、マイク不使用を強調。リジェクト防止の重要ポイント | REVIEW_NOTES.md に反映済み |
| **What's New テキスト** | マーケティングが用意した What's New テキストは審査対象外だが、技術的に正確な機能名を使用していることを確認済み | 確認済み |

### CDO / ブランド (03) との連携

| 観点 | 影響 | 対応状況 |
|------|------|----------|
| **ブランドボイス（静謐・端正・余白的）** | サポートページの FAQ 文体をブランドボイスに合わせた。簡潔で静かなトーン。感嘆符・絵文字・カジュアルすぎる表現を排除 | SUPPORT_STRATEGY.md に反映済み |
| **プライバシーポリシーのトーン** | 法的文書のため大幅なトーン変更は不適切。ただし、冗長な説明を削り、簡潔さを維持する方針はブランドと一致している。現状のトーンで問題なし | 変更不要と判断 |
| **スクリーンショット解像度** | CDO のビジュアル戦略（白背景、デバイスフレームなし、ドロップシャドウ）は審査要件と矛盾しない。解像度要件は TECHNICAL_METADATA.md に記載済み | 整合性確認済み |

### ビジネス / ASO (04) との連携

| 観点 | 影響 | 対応状況 |
|------|------|----------|
| **セカンダリカテゴリ: Lifestyle** | ASO の分析に基づき、セカンダリカテゴリを Utilities → Lifestyle に変更。Things 3, Bear と同じ文脈でのポジショニング | TECHNICAL_METADATA.md を更新済み |
| **価格: 1,500円 / $9.99** | TECHNICAL_METADATA.md に具体的な価格を追記 | TECHNICAL_METADATA.md を更新済み |
| **キーワード最適化** | ASO が策定した日英キーワードを TECHNICAL_METADATA.md に反映。App名・サブタイトルとの重複排除ルールも記載 | TECHNICAL_METADATA.md を更新済み |
| **Apple フィーチャー自薦** | 技術的アピールポイントを整理。下記「フィーチャー自薦の技術的根拠」セクションに記載 | 本ドキュメントに追記 |

---

## Apple フィーチャー自薦の技術的根拠

ASO チームが提案する Apple フィーチャー自薦（`apple.com/app-store/promote`）に向けて、技術面からアピールすべきポイントを整理する。

### Apple が重視する技術的要素と Kokukoku の対応

| Apple の評価軸 | Kokukoku の実装 |
|----------------|----------------|
| **Latest Apple technologies** | SwiftUI + SwiftData（最新のUI/データフレームワーク）。ActivityKit（Live Activity / Dynamic Island）。WidgetKit。WatchConnectivity。 |
| **Cross-platform experience** | iOS + macOS + watchOS のユニバーサル購入。共有コードベースで全プラットフォームをネイティブサポート。macOS は MenuBarExtra でネイティブ体験を提供（Mac Catalyst ではない） |
| **No third-party dependencies** | SPM / CocoaPods / Carthage いずれも不使用。Apple 純正フレームワークのみで構成。サードパーティ SDK ゼロ |
| **Privacy-first** | データ収集なし。分析 SDK なし。広告 SDK なし。App Privacy ラベル「Data Not Collected」 |
| **System integration depth** | Focus Mode 自動連携（INFocusStatusCenter）、Live Activity、Dynamic Island、Apple Watch 双方向同期、macOS MenuBarExtra、iOS Widget |
| **Design quality** | SF Pro / SF Mono のみ使用。SF Symbols。Vibrant material。標準的な Apple HIG に準拠したインタラクション |
| **Accessibility** | VoiceOver 対応。Dynamic Type 対応。monospacedDigit() によるタイマー数字の視認性確保 |

### 自薦メッセージの方向性（技術視点）

> Kokukoku demonstrates deep integration with the Apple ecosystem: Live Activity, Dynamic Island, Apple Watch via WatchConnectivity, macOS MenuBarExtra, Focus Mode automation, and WidgetKit -- all built with pure SwiftUI and SwiftData, zero third-party dependencies. It collects no user data and is a Universal Purchase across iOS, macOS, and watchOS.

---

## 未決定事項（要対応）

| 優先度 | タスク | ブロッカー |
|--------|--------|-----------|
| P0 | **サポート用メールアドレス** の決定・取得 | App Store 審査必須 |
| P0 | **GitHub Pages サイト** の構築（プライバシーポリシー・サポートページ） | App Store 審査必須 |
| P0 | **プライバシーポリシー URL** の確定 → App Store Connect に入力 | 上記サイト構築後 |
| P0 | **サポート URL** の確定 → App Store Connect に入力 | 上記サイト構築後 |
| P1 | **ソフトローンチ時の地域設定** — App Store Connect で日本のみに設定 | ローンチ判断後 |
| P1 | **Apple フィーチャー自薦** — ローンチ2-4週間前に申請 | ASO チームと連携 |
| P2 | **GitHub Issues テンプレート** の整備（bug_report.md, feature_request.md） | ローンチ前推奨 |
