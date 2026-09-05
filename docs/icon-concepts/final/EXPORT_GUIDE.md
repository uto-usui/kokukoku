# アプリアイコン書き出しガイド
Extensions: Install Extension
## ソース SVG

```
final/
├── icon-light.svg      ← iOS (default) + macOS 全サイズのソース
├── icon-dark.svg       ← iOS Dark のソース
└── icon-tinted.svg     ← iOS Tinted のソース
```

## 書き出しが必要なファイル（9ファイル）

### icon-light.svg から（7ファイル）

| 書き出し先 | px |
|-----------|-----|
| `export/ios/icon-ios-1024.png` | 1024x1024 |
| `export/macos/icon-mac-512.png` | 512x512 |
| `export/macos/icon-mac-256.png` | 256x256 |
| `export/macos/icon-mac-128.png` | 128x128 |
| `export/macos/icon-mac-32@2x.png` | 64x64 |
| `export/macos/icon-mac-32.png` | 32x32 |
| `export/macos/icon-mac-16.png` | 16x16 |

### icon-dark.svg から（1ファイル）

| 書き出し先 | px |
|-----------|-----|
| `export/ios/icon-ios-dark-1024.png` | 1024x1024 |

### icon-tinted.svg から（1ファイル）

| 書き出し先 | px |
|-----------|-----|
| `export/ios/icon-ios-tinted-1024.png` | 1024x1024 |

## コピー（Claude が実行）

書き出し後、以下のコマンドで同一ピクセルのファイルをコピー＆リネーム：

```bash
cd docs/icon-concepts/final/export/macos

# 32x32 → 16@2x
cp icon-mac-32.png icon-mac-16@2x.png

# 256x256 → 128@2x
cp icon-mac-256.png icon-mac-128@2x.png

# 512x512 → 256@2x
cp icon-mac-512.png icon-mac-256@2x.png

# 1024x1024 → 512@2x
cp ../ios/icon-ios-1024.png icon-mac-512@2x.png
```

## xcassets へのコピー

```bash
DEST=app/Kokukoku/Kokukoku/Assets.xcassets/AppIcon.appiconset

cp docs/icon-concepts/final/export/ios/*.png "$DEST/"
cp docs/icon-concepts/final/export/macos/*.png "$DEST/"
```

## 注意

- 小サイズ（16, 32, 64）でストロークが潰れる場合は専用 SVG を用意する
- macOS アイコンは Xcode が自動で角丸マスクを適用する
- Tinted 版は白背景 + 黒ストローク（iOS がユーザーのティント色を適用）
