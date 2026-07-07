#!/bin/bash
# Полная сборка JefPreview.app с подписью Developer ID (для распространения/нотаризации).
# Рендер нативный (Swift + Core Graphics) — Python/PyInstaller не используются.
#
# Использование:
#   CODESIGN_IDENTITY="Developer ID Application: Ваше Имя (TEAMID)" ./scripts/build_app.sh
#
# Требуется: Xcode, xcodegen (brew install xcodegen).
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

IDENTITY="${CODESIGN_IDENTITY:?Задайте CODESIGN_IDENTITY (см. security find-identity -v -p codesigning)}"

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

# Подпись inside-out: сначала каждый .appex, затем само приложение.
# hardened runtime + timestamp обязательны для нотаризации.
for APPEX in "$APP"/Contents/PlugIns/*.appex; do
  codesign --force --options runtime --timestamp \
    --entitlements "$ROOT/swift/Ext.entitlements" \
    -s "$IDENTITY" "$APPEX"
done

codesign --force --options runtime --timestamp \
  --entitlements "$ROOT/swift/App/App.entitlements" \
  -s "$IDENTITY" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "OK: $APP собран и подписан"
