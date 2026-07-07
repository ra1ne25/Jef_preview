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

### macOS

For local testing (ad-hoc signing, no Apple certificates):

```bash
brew install xcodegen
./scripts/build_app_dev.sh
cp -R build/JefPreview.app /Applications/
open /Applications/JefPreview.app
```

### Windows

Thumbnails and preview pane for `.jef` files in File Explorer (Quick Look equivalent).

**Download:** `JefPreview-1.0.0-win-x64-setup.exe` from [releases](https://github.com/ra1ne25/Jef_preview/releases/latest).

#### Installer

1. Run `JefPreview-*-win-x64-setup.exe` as Administrator
2. In Explorer: **View** → **Preview pane**
3. Select a `.jef` file

Requires [.NET 9 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/9.0). The installer checks and prompts if missing.

Uninstall: **Settings → Apps → JefPreview → Uninstall**

#### Build from source

**Requirements:** Windows 10/11, [.NET 9 SDK](https://dotnet.microsoft.com/download)

```powershell
.\windows\scripts\build.ps1
# Administrator PowerShell:
.\windows\scripts\register.ps1
```

**Installer package:**

```powershell
winget install JRSoftware.InnoSetup
.\windows\scripts\package.ps1
```

Full reinstall while developing: `.\windows\scripts\reinstall.ps1` (Administrator)

In Explorer: enable **Preview pane** (View → Preview pane) and select a `.jef` file.

Render test without registration:

```powershell
.\windows\build\JefPreview.Tools.exe render file.jef preview.png
```

Unregister: `.\windows\scripts\unregister.ps1`

## Project layout

```
swift/          Xcode project (app + Quick Look extensions)
windows/        Windows shell extension (C# + SharpShell)
scripts/        Build and packaging scripts (macOS)
samples/        Sample .jef file for testing
```
