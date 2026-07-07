#!/bin/bash
# Сборка PKG-инсталлятора + нотаризация.
#
# Использование:
#   INSTALLER_IDENTITY="Developer ID Installer: Ваше Имя (TEAMID)" \
#   NOTARY_PROFILE="jefpreview-notary" \
#   ./scripts/make_pkg.sh
#
# NOTARY_PROFILE создаётся один раз:
#   xcrun notarytool store-credentials jefpreview-notary \
#     --apple-id you@example.com --team-id TEAMID --password <app-specific-password>
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

VERSION="${VERSION:-1.0.0}"
INSTALLER_IDENTITY="${INSTALLER_IDENTITY:?Задайте INSTALLER_IDENTITY}"
APP="$ROOT/build/JefPreview.app"
[ -d "$APP" ] || { echo "Сначала запустите scripts/build_app.sh"; exit 1; }

PKGROOT="$ROOT/build/pkgroot"
rm -rf "$PKGROOT"
mkdir -p "$PKGROOT/Applications"
cp -R "$APP" "$PKGROOT/Applications/"

pkgbuild \
  --root "$PKGROOT" \
  --scripts "$ROOT/scripts/pkg" \
  --identifier com.flowdev.jefpreviwe \
  --version "$VERSION" \
  --install-location / \
  "$ROOT/build/JefPreview-component.pkg"

productbuild \
  --package "$ROOT/build/JefPreview-component.pkg" \
  --sign "$INSTALLER_IDENTITY" \
  "$ROOT/build/JefPreview-$VERSION.pkg"

if [ -n "${NOTARY_PROFILE:-}" ]; then
  xcrun notarytool submit "$ROOT/build/JefPreview-$VERSION.pkg" \
    --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$ROOT/build/JefPreview-$VERSION.pkg"
  echo "OK: пакет нотаризован и пришит (stapled)"
fi

echo "Готово: build/JefPreview-$VERSION.pkg"
