# 審査メモ（Review Notes）

App Store Connect の「App Review」セクションの「Notes for Review」に記載する内容です。

## 推奨テキスト（英語）

以下のテキストを App Store Connect の Review Notes フィールドにそのまま貼り付けてください。

---

```
Kokukoku is a Pomodoro timer app. No login or account is required — all features are immediately available upon launch. This is a one-time purchase app with no in-app purchases or subscriptions.

HOW TO TEST (iPhone / iPad):
1. Launch the app. The timer screen is displayed immediately.
2. Tap "Start" to begin a 25-minute focus session. The countdown begins.
3. Tap "Pause" to pause, "Resume" to continue.
4. Tap "Skip" to advance to the next session (Short Break → Focus → …).
5. Tap "Reset" to return to the initial state.
6. Open Settings (gear icon) to configure durations, auto-start, boundary stop policy, ambient noise, and notifications.
7. Session history is available via the History screen (clock icon). Completed sessions are filterable by type.
8. Enable "Ambient Noise" in Settings, then start a session — pink noise plays through AVAudioEngine.
9. If a Live Activity-capable device is used, remaining time appears on the Lock Screen and Dynamic Island during an active session.

HOW TO TEST (macOS):
1. Launch the app. A compact 380×640 window appears.
2. The menu bar shows a status item with the remaining time during active sessions.
3. Click the menu bar item to access timer controls (Start/Pause/Resume, Skip, Reset) without opening the main window.
4. All timer and settings functionality matches the iOS version.

HOW TO TEST (Apple Watch):
1. Ensure the Watch app is installed on a paired Apple Watch.
2. Start a timer on iPhone — the Watch app reflects the current session state via WatchConnectivity.
3. The Watch app displays remaining time and session type. Timer controls are available from the Watch.

AUDIO USAGE:
This app uses AVAudioEngine exclusively for real-time pink noise generation during focus sessions. This is a playback-only feature for ambient background sound. The app does NOT record audio and does NOT access the microphone. No NSMicrophoneUsageDescription is declared because microphone access is not used.

NOTIFICATIONS:
Local notifications are used to alert the user when a timer session completes. No push notifications or remote notification services are used.

FOCUS STATUS:
The app reads the system Focus Mode status (via INFocusStatusCenter) to automatically mute notification sounds when Focus is active. This is a read-only check; the app does not modify Focus Mode settings.

DATA PRIVACY:
No user data is collected, transmitted, or stored on external servers. All data (timer settings, session history) is stored locally on-device using SwiftData. No analytics SDKs, advertising SDKs, crash reporting services, or any third-party services are included. The app has zero third-party dependencies.

DEVICE-TO-DEVICE SYNC:
Timer state is synchronized between iPhone and Apple Watch using Apple's WatchConnectivity framework. This communication occurs directly between paired devices through Apple's system frameworks and does not pass through any external server.

PLATFORMS:
- iPhone and iPad (iOS 26.2+)
- Mac (macOS 15.7+, native SwiftUI with MenuBarExtra — not Mac Catalyst)
- Apple Watch (watchOS 26.2+, companion app via WatchConnectivity)
- Widget and Live Activity (iOS, via WidgetKit and ActivityKit)

UNIVERSAL PURCHASE:
This is a universal purchase app. A single purchase grants access on all supported Apple platforms (iOS, macOS, watchOS).

FRAMEWORKS USED:
SwiftUI, SwiftData, AVFoundation (AVAudioEngine), ActivityKit, WidgetKit, WatchConnectivity, UserNotifications, Intents (INFocusStatusCenter). No third-party frameworks or SDKs.
```

---

## 審査メモの日本語訳（参考）

```
Kokukoku はポモドーロタイマーアプリです。ログインやアカウントは不要で、起動直後にすべての機能を利用できます。買い切り型のアプリで、アプリ内課金やサブスクリプションはありません。

テスト方法（iPhone / iPad）:
1. アプリを起動します。タイマー画面が即座に表示されます。
2. 「開始」をタップして25分の集中セッションを開始します。
3. 「一時停止」で停止、「再開」で続行できます。
4. 「スキップ」で次のセッション（小休憩 → 集中 → …）に進みます。
5. 「リセット」で初期状態に戻ります。
6. 設定（歯車アイコン）から、時間設定・自動開始・停止ポリシー・環境音・通知を構成できます。
7. 履歴画面（時計アイコン）でセッション履歴を確認できます。種類別にフィルタリング可能です。
8. 設定で「環境音」を有効にしてセッションを開始すると、AVAudioEngine によるピンクノイズが再生されます。
9. Live Activity 対応デバイスでは、セッション中にロック画面と Dynamic Island に残り時間が表示されます。

テスト方法（macOS）:
1. アプリを起動します。380×640 のコンパクトなウィンドウが表示されます。
2. セッション中、メニューバーに残り時間が表示されます。
3. メニューバーアイテムをクリックすると、メインウィンドウを開かずにタイマー操作ができます。
4. すべてのタイマー・設定機能は iOS 版と同等です。

テスト方法（Apple Watch）:
1. ペアリング済みの Apple Watch に Watch アプリがインストールされていることを確認してください。
2. iPhone でタイマーを開始すると、Watch アプリに WatchConnectivity 経由で状態が反映されます。
3. Watch アプリで残り時間とセッション種別を確認でき、タイマー操作も可能です。

オーディオの使用について:
AVAudioEngine は集中セッション中のピンクノイズ（環境音）のリアルタイム生成にのみ使用しています。再生専用の機能であり、音声の録音やマイクへのアクセスは一切行いません。

通知について:
ローカル通知をタイマーセッション完了の通知に使用します。プッシュ通知やリモート通知サービスは使用していません。

集中モードについて:
INFocusStatusCenter を通じてシステムの集中モード状態を読み取り、集中モード中の通知音を自動ミュートします。読み取り専用であり、集中モードの設定を変更することはありません。

データプライバシー:
ユーザーデータの収集・送信・外部サーバーへの保存は行いません。すべてのデータは SwiftData を使用してデバイス上にローカル保存されます。サードパーティの依存関係はゼロです。

デバイス間同期:
iPhone と Apple Watch 間のタイマー状態同期は Apple の WatchConnectivity フレームワークを使用します。通信はペアリングされたデバイス間で直接行われ、外部サーバーを経由しません。
```

## 補足: よくある審査リジェクト要因と対策

| リジェクト要因 | Kokukoku での対策 |
|---|---|
| マイク使用理由の説明不足 | マイクは使用しない。AVAudioEngine は再生のみ。NSMicrophoneUsageDescription は不要かつ未宣言。Review Notes で明確に説明済み |
| ログインなしでテスト不可 | ログイン不要。起動直後に全機能利用可能 |
| 通知の目的が不明 | セッション完了のローカル通知のみ。Review Notes に明記 |
| プライバシーポリシー URL 未設定 | 公開済み URL を App Store Connect に設定する（GitHub Pages） |
| 有料アプリで機能が不十分 | ポモドーロタイマーとしてフル機能を提供。iOS + macOS + watchOS のユニバーサル購入で価格を正当化 |
| Apple Watch アプリのテスト手順が不明 | Review Notes に Watch 固有のテスト手順を記載 |
| Live Activity の説明不足 | Review Notes に ActivityKit 使用の説明と確認方法を記載 |
| 第三者フレームワークの使用目的不明 | サードパーティ依存ゼロ。使用フレームワーク一覧を Review Notes 末尾に明記 |

## ソフトローンチ時の注意事項

プロダクトプランナーのローンチ戦略（日本先行 → グローバル展開）に伴い:

1. **初回審査**: Review Notes は英語で記述（Apple 審査チームは英語ベース）。日本のみの地域限定公開でも審査メモの言語を変える必要はない
2. **地域設定**: App Store Connect の「Pricing and Availability」で初回は日本のみを選択。グローバル展開時に全リージョンへ拡大
3. **グローバル展開時**: Review Notes の再提出は不要（内容に変更がなければ）。ただし新機能追加がある場合は更新
4. **プライバシーポリシー URL**: 日本語版・英語版の両方を GitHub Pages で公開し、英語版を App Store Connect のデフォルト URL に設定
