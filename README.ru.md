# JefPreview

**[English](README.md)** · **[Русский](README.ru.md)**

Quick Look-плагин для macOS: миниатюры и предпросмотр (пробел) файлов вышивки `.jef` (Janome) в Finder.

Рендер полностью нативный — Swift + Core Graphics, без внешних зависимостей.

## Скачать

**[Последний релиз](https://github.com/ra1ne25/Jef_preview/releases/latest)** — скачайте `JefPreview-1.0.0.pkg`.

### Установка

1. Откройте файл `.pkg`
2. Нажмите **Продолжить** и введите пароль
3. `JefPreview.app` установится в `/Applications`
4. Запустите приложение один раз — зарегистрирует расширения Quick Look

### Требования

- macOS 13 (Ventura) или новее

## Использование

Выделите `.jef` в Finder и нажмите **пробел** для полного предпросмотра. Миниатюры появляются автоматически в режиме значков.

Если превью не появляется:

1. Откройте **Системные настройки → Основные → Объекты входа и расширения → Quick Look**
2. Включите расширения JefPreview
3. Выполните `qlmanage -r && qlmanage -r cache && killall Finder`

## Сборка из исходников

### macOS

Для локального тестирования (ad-hoc подпись, без сертификатов Apple):

```bash
brew install xcodegen
./scripts/build_app_dev.sh
cp -R build/JefPreview.app /Applications/
open /Applications/JefPreview.app
```

### Windows

Миниатюры и панель предпросмотра `.jef` в Проводнике (аналог Quick Look).

**Скачать:** `JefPreview-1.0.0-win-x64-setup.exe` из [релизов](https://github.com/ra1ne25/Jef_preview/releases/latest).

#### Установка (инсталлятор)

1. Запустите `JefPreview-*-win-x64-setup.exe` от администратора
2. Откройте Проводник → **Вид** → **Область просмотра**
3. Выделите файл `.jef`

Удаление: **Параметры → Приложения → JefPreview → Удалить**

#### Сборка из исходников

**Требования:** Windows 10/11, [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)

```powershell
.\windows\scripts\build.ps1
# PowerShell от администратора:
.\windows\scripts\register.ps1
```

Для dev-сборки нужен [.NET 9 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/9.0) на машине пользователя.

**Инсталлятор** (~3 MB, требуется [.NET 9 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/9.0)):

```powershell
winget install JRSoftware.InnoSetup   # один раз
.\windows\scripts\package.ps1
# -> windows\dist\JefPreview-1.0.0-win-x64-setup.exe
```

Полная переустановка при разработке:

```powershell
.\windows\scripts\reinstall.ps1   # от администратора
```

В Проводнике: включите **Область просмотра** (Вид → Область просмотра) и выделите `.jef`.

Тест рендера без регистрации:

```powershell
.\windows\build\JefPreview.Tools.exe render file.jef preview.png
```

Удаление: `.\windows\scripts\unregister.ps1`

Если превью пустое — смотрите лог `%LOCALAPPDATA%\JefPreview\preview.log` (или `%TEMP%\JefPreview-preview.log`).

После изменения размера панели превью, если пропало: `Get-Process prevhost,dllhost | Stop-Process -Force`, затем `.\windows\scripts\register.ps1`

## Структура проекта

```
swift/          Xcode-проект (приложение + расширения Quick Look)
windows/        Windows shell extension (C# + SharpShell)
scripts/        Скрипты сборки и упаковки (macOS)
samples/        Тестовый .jef файл
```
