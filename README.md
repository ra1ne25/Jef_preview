# JefPreview

**[English](README.md)** · **[Русский](README.ru.md)**

Quick Look plugin for macOS: thumbnails and Space-bar preview of Janome `.jef` embroidery files in Finder.

Native rendering — Swift + Core Graphics, no external dependencies.

## Download

**[Latest release](https://github.com/ra1ne25/Jef_preview/releases/latest)** — download `JefPreview-1.0.0.pkg`.

### Install

1. Open the `.pkg` file
2. Click **Continue** and enter your password
3. `JefPreview.app` is installed to `/Applications`
4. Open the app once to register Quick Look extensions

### Requirements

- macOS 13 (Ventura) or later

## Usage

Select a `.jef` file in Finder and press **Space** for a full preview. Thumbnails appear automatically in icon view.

If previews don't show up:

1. Open **System Settings → General → Login Items & Extensions → Quick Look**
2. Enable JefPreview extensions
3. Run `qlmanage -r && qlmanage -r cache && killall Finder`

## Build from source

For local testing (ad-hoc signing, no Apple certificates):

```bash
brew install xcodegen
./scripts/build_app_dev.sh
cp -R build/JefPreview.app /Applications/
open /Applications/JefPreview.app
```

## Project layout

```
swift/          Xcode project (app + Quick Look extensions)
scripts/        Build and packaging scripts
samples/        Sample .jef file for testing
```
