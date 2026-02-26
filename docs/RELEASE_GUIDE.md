# Kokukoku リリースガイド

## 前提条件

- Apple Developer Program 登録済み ($99/年)
- Xcode にコード署名証明書が設定済み
- `make ci` が通っている

---

## 1. リリース前の品質ゲート

```bash
make ci   # lint + test-macos + build-ios
```

全パスを確認してから次へ。

## 2. CHANGELOG バージョンカット

`CHANGELOG.md` の `[Unreleased]` セクションをバージョン番号に変更:

```markdown
## [0.2.0] - 2026-02-26
```

コミット & プッシュ。

## 3. Xcode アーカイブ & アップロード

1. Xcode で `app/Kokukoku/Kokukoku.xcodeproj` を開く
2. スキーム: **Kokukoku**、Destination: **Any iOS Device (arm64)**
3. **Product → Archive**
4. Organizer が開く → **Distribute App** → **App Store Connect** → **Upload**
5. バージョン番号と Build 番号を設定
   - Version: `0.2.0`（CHANGELOG と一致させる）
   - Build: `1`（同バージョンで再アップロードする場合はインクリメント）

### CLI でやる場合（2回目以降の自動化用）

```bash
# アーカイブ
xcodebuild -project app/Kokukoku/Kokukoku.xcodeproj \
  -scheme Kokukoku \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath build/Kokukoku.xcarchive \
  archive

# IPA 書き出し（ExportOptions.plist は別途作成が必要）
xcodebuild -exportArchive \
  -archivePath build/Kokukoku.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist

# アップロード
xcrun altool --upload-app -f build/Kokukoku.ipa \
  -t ios \
  -u "your@apple.id" \
  -p "@keychain:AC_PASSWORD"
```

## 4. App Store Connect メタデータ

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) にログイン。

### アプリ情報

| 項目 | 値 |
|------|-----|
| 名前 | Kokukoku |
| サブタイトル（日本語） | 時を刻む、ただそれだけ。 |
| サブタイトル（英語） | Carve your time. |
| カテゴリ | Productivity |
| 価格 | ¥1,500 / $9.99（買い切り、ユニバーサル購入） |

### スクリーンショット（必須）

| デバイス | サイズ | 最低枚数 |
|---------|-------|---------|
| iPhone 6.9" | 1320 x 2868 | 1 |
| iPad 13" | 2064 x 2752 | 1（ユニバーサルアプリの場合） |
| Mac | 適宜 | 推奨 |

Simulator で `Cmd+S` でキャプチャ可能。

### その他の必須項目

- **説明文**: アプリの概要（日本語 + 英語）
- **キーワード**: pomodoro, timer, focus, productivity, kokukoku 等
- **プライバシーポリシー URL**: データ収集なしでも URL は必須。簡易なページで OK
- **サポート URL**: GitHub リポジトリ or 専用ページ
- **App Review 情報**: ログイン不要の旨を記載

## 5. TestFlight 内部テスト

アップロード後、App Store Connect → TestFlight に自動でビルドが表示される。

1. 内部テスターに自分を追加（初回のみ）
2. ビルドを選択 → テスト開始
3. 実機で以下を確認:
   - タイマー開始 → 通知が届く
   - バックグラウンド復帰で残り時間がずれない
   - Apple Watch 連携（ペアリング済みの場合）
   - Ambient Noise の音質・他アプリとの共存
   - 設定変更が即座に反映される

## 6. 審査提出

TestFlight で問題なければ:

1. App Store Connect → アプリ → バージョン情報ページ
2. ビルドを選択
3. **審査に提出**

### 審査メモ（例）

```
Pomodoro timer app. No login required.
All features are accessible immediately after launch.
No in-app purchases or subscriptions.
```

### 審査期間

通常 24-48 時間。リジェクトされた場合はフィードバックに対応して再提出。

---

## リリース後

- [ ] App Store に公開されたことを確認
- [ ] git tag を打つ: `git tag v0.2.0 && git push origin v0.2.0`
- [ ] CHANGELOG の次の `[Unreleased]` セクションを追加
