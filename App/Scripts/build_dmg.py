#!/usr/bin/env python3
"""
Genera el .dmg de instalación de Micro con dmgbuild: escribe el .DS_Store
(ventana, iconos, fondo) directamente en bytes, sin pasar por automatizar
Finder vía AppleScript.

Por qué: la receta anterior (create-dmg + AppleScript) resultó poco fiable
para fijar el fondo — Finder podía "aceptar" el comando sin dar ningún
error y aun así no grabarlo en el .DS_Store, de forma intermitente y sin
relación con permisos ni con el propio script (confirmado inspeccionando el
.DS_Store resultante byte a byte). dmgbuild no depende de que Finder tenga
una ventana abierta e interactiva: genera el .DS_Store como datos, por lo
que el resultado es el mismo las veces que se ejecute.

Uso: python3 Scripts/build_dmg.py <Micro.app> <dmg_background.png> <salida.dmg>
"""
import sys
import dmgbuild

if len(sys.argv) != 4:
    print(f"Uso: {sys.argv[0]} <app> <background.png> <salida.dmg>")
    sys.exit(1)

app_path, background_path, output_path = sys.argv[1:4]
app_name = app_path.rstrip("/").split("/")[-1]

settings = {
    "format": "UDZO",
    "filesystem": "HFS+",
    "files": [app_path],
    "symlinks": {"Applications": "/Applications"},
    "background": background_path,
    "show_status_bar": False,
    "show_tab_view": False,
    "show_toolbar": False,
    "show_pathbar": False,
    "show_sidebar": False,
    "arrange_by": None,
    "icon_size": 128,
    "text_size": 16,
    "window_rect": ((100, 100), (600, 420)),
    "default_view": "icon-view",
    "icon_locations": {
        app_name: (160, 230),
        "Applications": (440, 230),
    },
}

dmgbuild.build_dmg(
    filename=output_path,
    volume_name="Install Micro",
    settings=settings,
    # La combinación @1x/@2x en un único TIFF "HiDPI" salía descuadrada
    # (el fondo se veía más grande que la ventana, desplazado). Con un
    # único PNG a tamaño normal, Finder lo coloca sin ambigüedad.
    lookForHiDPI=False,
)
print(f"DMG listo: {output_path}")
