#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="Micro.app"
rm -rf "$APP" MiniPlayer.app
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/MiniPlayerApp "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
if [ -f Resources/MenuBarIcon.png ]; then
  cp Resources/MenuBarIcon.png Resources/MenuBarIcon@2x.png "$APP/Contents/Resources/"
fi

# firma ad-hoc: ayuda a que WebKit trate el bundle de forma consistente
# entre ejecuciones (persistencia de cookies, XPC, etc.)
codesign --force --deep --sign - "$APP"

# instalar en /Applications (la de verdad, no ~/Applications) para que
# quede igual que como la instala cualquiera desde el .dmg
rm -rf "/Applications/$APP"
cp -R "$APP" "/Applications/$APP"

# registrar el bundle (y por tanto el esquema micro://) en Launch Services
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -f "/Applications/$APP"

echo "Listo: /Applications/$APP"
