#!/bin/bash
# Локальная сборка JefPreview.app для теста в Finder БЕЗ Developer ID и нотаризации.
# Использует ad-hoc подпись (codesign -s -): работает только на этой машине,
# аккаунт Apple не требуется. Для распространения используйте scripts/build_app.sh.
#
# Использование:
#   ./scripts/build_app_dev.sh
#
# Требуется: Xcode, xcodegen (brew install xcodegen).
# Рендер теперь нативный (Swift + Core Graphics) — Python/PyInstaller не нужны.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

IDENTITY="-"   # ad-hoc: без сертификата, без таймстампа, без hardened runtime

# Xcode-проект и сборка (без подписи — подписываем сами, inside-out)
cd swift
xcodegen generate
xcodebuild -project JefPreview.xcodeproj -scheme JefPreview -configuration Release \
  -derivedDataPath "$ROOT/build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build
cd "$ROOT"

APP="$ROOT/build/JefPreview.app"
rm -rf "$APP"
cp -R "$ROOT/build/DerivedData/Build/Products/Release/JefPreview.app" "$APP"

# Подпись inside-out (ad-hoc): каждый .appex, затем само приложение.
# Хелпера-бинарника больше нет — рендер нативный, подписывать нечего кроме кода Swift.
# Отличия от боевой сборки: нет --timestamp и нет --options runtime,
# т.к. ad-hoc подпись их не поддерживает (и для локали они не нужны).
for APPEX in "$APP"/Contents/PlugIns/*.appex; do
  codesign --force \
    --entitlements "$ROOT/swift/Ext.entitlements" \
    -s "$IDENTITY" "$APPEX"
done

codesign --force \
  --entitlements "$ROOT/swift/App/App.entitlements" \
  -s "$IDENTITY" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"

echo
echo "OK: $APP собран и подписан ad-hoc."
echo
echo "Дальше — установить и проверить:"
echo "  cp -R \"$APP\" /Applications/"
echo "  open /Applications/JefPreview.app          # запустить один раз (регистрирует расширения)"
echo "  pluginkit -m -v | grep -i jefpreview       # убедиться, что расширения видны"
echo "  qlmanage -r && qlmanage -r cache           # сбросить кэш QuickLook"
echo "  qlmanage -p \"$ROOT/samples/test.jef\"       # тест предпросмотра"
echo "  qlmanage -t -s 512 \"$ROOT/samples/test.jef\" # тест миниатюры"
echo
echo "Затем в Finder выдели любой .jef и нажми пробел."
echo "Если пусто: System Settings → General → Login Items & Extensions → Quick Look —"
echo "включи расширения JefPreview, потом killall Finder."
