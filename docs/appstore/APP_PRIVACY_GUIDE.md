# App Privacy 回答ガイド

App Store Connect の「App Privacy」セクションで入力する内容のガイドです。

## 概要

Kokukoku はユーザーデータを一切収集しないため、App Privacy の設定は非常にシンプルです。

## 手順

### 1. App Store Connect にアクセス

1. [App Store Connect](https://appstoreconnect.apple.com) にログイン
2. 「マイ App」から「Kokukoku」を選択
3. 左サイドバーの「App のプライバシー」をクリック

### 2. プライバシーポリシー URL の入力

- **プライバシーポリシー URL**: 公開したプライバシーポリシーの URL を入力
  - 例: `https://github.com/okiniirinoao/kokukoku/blob/main/docs/appstore/PRIVACY_POLICY_EN.md`
  - または専用の GitHub Pages / 静的サイトの URL

### 3. データ収集の質問に回答

Apple は以下の質問を表示します。

#### 「Do you or your third-party partners collect data from this app?」

**回答: No（いいえ）**

この選択により、App Store の製品ページに以下が表示されます:

> **Data Not Collected**
> The developer does not collect any data from this app.

### 4. 確認事項

「No」を選択する前に、以下をすべて確認してください（Kokukoku はすべて該当します）:

| チェック項目 | 状態 |
|---|---|
| サードパーティの分析 SDK を使用していない | 該当（使用していない） |
| サードパーティの広告 SDK を使用していない | 該当（使用していない） |
| サードパーティのクラッシュレポートを使用していない | 該当（使用していない） |
| ユーザーデータを外部に送信していない | 該当（送信していない） |
| デバイス識別子を収集していない | 該当（収集していない） |
| 位置情報を収集していない | 該当（収集していない） |
| ログイン/アカウント機能がない | 該当（ない） |

### 5. 補足: Nutrition Labels の各カテゴリ

参考として、Apple が定義するデータカテゴリと Kokukoku の該当状況を記載します。

| カテゴリ | 収集するか |
|---|---|
| Contact Info | No |
| Health & Fitness | No |
| Financial Info | No |
| Location | No |
| Sensitive Info | No |
| Contacts | No |
| User Content | No |
| Browsing History | No |
| Search History | No |
| Identifiers | No |
| Usage Data | No |
| Diagnostics | No |
| Other Data | No |

**すべて「No」です。**

## 注意事項

- App Privacy の回答は、アプリのアップデート時にも確認・更新が求められます。将来的にデータ収集を開始する場合は必ず更新してください。
- Apple の WatchConnectivity や UserNotifications はデバイスローカルの機能であり、「データ収集」には該当しません。
- AVAudioEngine によるオーディオ再生も、録音を行わないため「データ収集」には該当しません。
