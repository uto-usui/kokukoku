# 技術メタデータ

App Store Connect で入力が必要な技術情報のまとめです。

## 基本情報

| 項目 | 値 |
|---|---|
| アプリ名 | Kokukoku |
| Bundle ID | com.uto-usui.Kokukoku |
| SKU | kokukoku-pomodoro（任意の一意識別子） |
| マーケティングバージョン | 1.0 |
| カテゴリ（プライマリ） | Productivity（仕事効率化） |
| カテゴリ（セカンダリ） | Lifestyle（ライフスタイル） |
| コンテンツレーティング | 4+ |
| 価格 | 有料・買い切り（日本: 1,500円 / 米国: $9.99） |
| 著作権表示 | (c) 2026 okiniirinoao |

> **セカンダリカテゴリの根拠:** ASO 分析により、Utilities から Lifestyle に変更。Things 3、Bear と同じ文脈でのポジショニング。競合密度が低く、ブランドイメージ（道具としての品格）と一致する。

## プラットフォームと最小バージョン

| プラットフォーム | 最小OS バージョン | 備考 |
|---|---|---|
| iPhone | iOS 26.2 | ユニバーサル（iPhone + iPad） |
| iPad | iPadOS 26.2 | iPhone アプリとして自動対応 |
| Mac | macOS 15.7 | ネイティブ SwiftUI（Mac Catalyst ではない）、MenuBarExtra 対応 |
| Apple Watch | watchOS 26.2 | コンパニオンアプリ（WatchConnectivity） |

## ターゲットと Bundle ID

| ターゲット | Bundle ID | 種別 |
|---|---|---|
| Kokukoku（メインアプリ） | com.uto-usui.Kokukoku | Application |
| KokukokuWidget | com.uto-usui.Kokukoku.widget | App Extension（WidgetKit） |
| KokukokuWatch | com.uto-usui.Kokukoku.watchkitapp | watchOS Application |

## 使用フレームワーク

| フレームワーク | 用途 | プラットフォーム |
|---|---|---|
| SwiftUI | UI 全般 | 全プラットフォーム |
| SwiftData | ローカルデータ永続化（設定、セッション履歴） | iOS, macOS |
| AVFoundation / AVAudioEngine | ピンクノイズ生成・再生 | iOS, macOS |
| ActivityKit | Live Activity / Dynamic Island | iOS のみ |
| WidgetKit | ホーム画面 Widget、Live Activity Widget | iOS のみ |
| WatchConnectivity | iPhone-Watch 間の状態同期 | iOS, watchOS |
| UserNotifications | ローカル通知 | iOS, macOS, watchOS |
| Intents (INFocusStatusCenter) | Focus Mode 状態取得 | iOS, macOS, watchOS |

**サードパーティ依存: なし。** SPM / CocoaPods / Carthage いずれも不使用。Apple 純正フレームワークのみで構成。

## ユニバーサル購入（Universal Purchase）

- **有効にする**: はい
- 1回の購入で iPhone、iPad、Mac、Apple Watch のすべてで利用可能
- App Store Connect の「Pricing and Availability」で「Universal Purchase」を有効化
- マーケティングコピーでも「ユニバーサル購入」を訴求ポイントとして明記している

## 価格設定

| 地域 | 価格 | 備考 |
|------|------|------|
| 日本 | 1,500円 | ソフトローンチの主戦場 |
| 米国 | $9.99 | グローバルローンチ後の主戦場 |
| 欧州 | EUR 9.99 | Apple 自動換算で概ね適正 |
| その他 | Apple の推奨価格帯に準拠 | |

> **価格の根拠:** ユニバーサル購入（iOS + macOS + watchOS を1購入でカバー）が正当化の柱。サブスク型の同等機能アプリは年3,400-4,900円。Things 3 (3,800円)、Bear を使う層がターゲット。詳細は `docs/store/04-business-aso.md` を参照。

## 暗号化（Export Compliance）

| 質問 | 回答 |
|---|---|
| Does your app use encryption? | **No** |

Kokukoku は独自の暗号化を実装していません。Apple の標準フレームワーク（SwiftData、WatchConnectivity）が内部的に使用する暗号化は、Apple のプラットフォーム暗号化であり、輸出規制の対象外です。

> Apple のドキュメントによると、iOS/macOS 標準の暗号化のみを使用するアプリは、年次の自己分類報告（Annual Self-Classification Report）の提出も不要です。

## App Store Connect での設定手順

### 1. 新規 App の作成

1. App Store Connect にログイン
2. 「マイ App」→「+」→「新規 App」
3. プラットフォーム: iOS, macOS（ユニバーサル購入を有効化）
4. 名前: Kokukoku
5. プライマリ言語: 日本語（English もローカライズ対応済み）
6. Bundle ID: com.uto-usui.Kokukoku
7. SKU: kokukoku-pomodoro

### 2. バージョン情報の入力

- **What's New**: 初回リリースのため不要（2回目以降に記載）
- **プロモーションテキスト**: `docs/store/02-marketing-copywriting.md` のプロモーションテキストを使用
- **説明**: `docs/store/02-marketing-copywriting.md` の説明文を使用
- **サポート URL**: `https://okiniirinoao.github.io/kokukoku/support`
- **プライバシーポリシー URL**: `https://okiniirinoao.github.io/kokukoku/privacy`
- **マーケティング URL**: `https://okiniirinoao.github.io/kokukoku/`（任意）

### 3. サブタイトル（30文字以内）

| 言語 | サブタイトル | 備考 |
|------|-------------|------|
| 日本語 | ポモドーロタイマー | シンプルに機能を伝える |
| 英語 | Pomodoro Timer for Apple | Apple エコシステム統合を示唆 |

> プロダクトプランナーの提案に準拠。サブタイトルに含まれる語はキーワードフィールドから除外する。

### 4. キーワード（100文字以内）

ASO 分析に基づく最適化済みキーワード。App 名（Kokukoku）およびサブタイトルに含まれる語は除外済み。

**日本語（86文字）:**
```
ポモドーロ,タイマー,集中,作業,勉強,仕事効率化,集中力,25分,休憩,Apple Watch,ウィジェット,買い切り,通知,ホワイトノイズ,ライブアクティビティ,メニューバー,時間管理
```

**英語（99文字）:**
```
pomodoro,timer,focus,concentration,productivity,study,work,25 minutes,break,widget,live activity,noise
```

> キーワード設計の詳細な根拠は `docs/store/04-business-aso.md` を参照。

### 5. スクリーンショットの準備

以下のデバイスサイズのスクリーンショットが必要です。ビジュアル戦略は `docs/store/03-brand-visual-strategy.md` を参照。

| デバイス | 解像度 | 必須 | 枚数 |
|---|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320 x 2868 | はい | 5枚 |
| iPhone 6.3" (iPhone 16 Pro) | 1206 x 2622 | はい | 5枚 |
| iPad 13" (iPad Pro M4) | 2064 x 2752 | iPad 対応の場合 | 4枚 |
| Mac | 最低 1280 x 800 | macOS 対応の場合 | 4枚 |
| Apple Watch | 各サイズ | watchOS 対応の場合 | - |

### 6. アプリアイコン

- 1024 x 1024 px（PNG、透過なし）
- Light / Dark / Tinted の3バリアント対応済み
- App Store Connect にアップロード（Xcode Archive に含まれていれば自動）

### 7. ビルドのアップロード

```bash
# Xcode から Archive → Distribute App → App Store Connect
# または Transporter アプリを使用
```

## Info.plist に必要なキー

| キー | 値 | 用途 |
|---|---|---|
| NSUserNotificationsUsageDescription | セッション完了時にお知らせするため通知を使用します | 通知権限の説明（iOS） |
| NSFocusStatusUsageDescription | 集中モード中の通知音の自動ミュートに使用します | Focus Status 権限の説明 |
| NSSupportsLiveActivities | YES | Live Activity の有効化（Info.plist or build settings） |

> **注意**: NSMicrophoneUsageDescription は **不要** です。AVAudioEngine は再生のみに使用しており、マイクにはアクセスしません。

## ソフトローンチ時の地域設定

プロダクトプランナーのローンチ戦略に基づき:

| フェーズ | Pricing and Availability 設定 |
|----------|-------------------------------|
| ソフトローンチ（1-2週） | 日本のみを選択 |
| グローバルローンチ（3週目以降） | 全リージョンに拡大 |

地域の拡大は App Store Connect の「Pricing and Availability」からいつでも変更可能。審査の再提出は不要。
