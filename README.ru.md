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

Для локального тестирования (ad-hoc подпись, без сертификатов Apple):

```bash
brew install xcodegen
./scripts/build_app_dev.sh
cp -R build/JefPreview.app /Applications/
open /Applications/JefPreview.app
```

## Структура проекта

```
swift/          Xcode-проект (приложение + расширения Quick Look)
scripts/        Скрипты сборки и упаковки
samples/        Тестовый .jef файл
```
