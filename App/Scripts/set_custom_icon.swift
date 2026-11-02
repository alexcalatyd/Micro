#!/usr/bin/swift
import AppKit

// Fuerza un icono personalizado (azul plano) sobre un archivo/carpeta,
// saltándose el sistema de variantes claro/oscuro/tintado automáticas que
// macOS genera para el icono "en vivo" de una app registrada. Se usa SOLO
// sobre la copia de Micro.app que va dentro del .dmg — la instalada de
// verdad se lo quita sola al primer arranque (ver AppDelegate.swift),
// para seguir el tema del sistema como una app normal.
let args = CommandLine.arguments
guard args.count == 3 else {
    print("Uso: set_custom_icon.swift <ruta> <icono.icns>")
    exit(1)
}
guard let icon = NSImage(contentsOfFile: args[2]) else {
    print("No pude cargar el icono en \(args[2])")
    exit(1)
}
let ok = NSWorkspace.shared.setIcon(icon, forFile: args[1], options: [])
print(ok ? "Icono personalizado aplicado a \(args[1])" : "Fallo al aplicar el icono")
exit(ok ? 0 : 1)
