#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Micro"
DMG_FINAL="$APP_NAME.dmg"

swift build -c release

rm -rf "$DMG_FINAL" "$APP_NAME.app"
mkdir -p "$APP_NAME.app/Contents/MacOS" "$APP_NAME.app/Contents/Resources"
cp .build/release/MiniPlayerApp "$APP_NAME.app/Contents/MacOS/"
cp Info.plist "$APP_NAME.app/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_NAME.app/Contents/Resources/AppIcon.icns"
cp Resources/MenuBarIcon.png Resources/MenuBarIcon@2x.png "$APP_NAME.app/Contents/Resources/"
codesign --force --deep --sign - "$APP_NAME.app"

# Icono fijo (azul plano) SOLO para esta copia, la que va dentro del .dmg:
# así se ve igual en claro y en oscuro ahí dentro, sin que macOS le aplique
# su variante oscura automática. La app, al arrancar ya instalada, se quita
# este icono personalizado sola (ver AppDelegate.swift) para volver a
# seguir el tema del sistema como una app normal.
swift Scripts/set_custom_icon.swift "$APP_NAME.app" "Resources/AppIcon.icns"

# Genera el .DS_Store (ventana, iconos, fondo) escribiéndolo directamente en
# bytes con dmgbuild, en vez de automatizar Finder por AppleScript (ver
# Scripts/build_dmg.py para el porqué: esa vía resultaba poco fiable).
if ! python3 -c "import dmgbuild" 2>/dev/null; then
  echo "Instalando dmgbuild (una sola vez)..."
  pip3 install --break-system-packages --quiet dmgbuild
fi

python3 Scripts/build_dmg.py "$APP_NAME.app" "Resources/dmg_background.png" "$DMG_FINAL"
