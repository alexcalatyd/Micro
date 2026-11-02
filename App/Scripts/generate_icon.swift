#!/usr/bin/swift
import AppKit

// Diseño minimalista a dos colores: fondo azul plano, y el contorno blanco
// de una ventana flotante que se "abre" justo en la esquina inferior
// derecha, por donde pasa una flechita de redimensionar — alude a que es
// una ventana flotante que se puede agrandar o encoger.
func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgPath = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.93, alpha: 1.0).setFill()
    bgPath.fill()

    // Marco de la ventana: contorno blanco con un hueco en la esquina
    // inferior derecha, por el que "atraviesa" la flecha de redimensionar.
    let winRect = rect.insetBy(dx: size * 0.24, dy: size * 0.24)
    let r = size * 0.11
    let gap = size * 0.21
    let lineWidth = size * 0.06

    let winPath = NSBezierPath()
    // Empieza en el hueco del lado derecho y sube por el borde derecho,
    // esquina superior derecha, borde superior, esquina superior izquierda,
    // borde izquierdo, esquina inferior izquierda, borde inferior, hasta
    // el hueco del lado inferior. La esquina inferior derecha queda abierta.
    winPath.move(to: NSPoint(x: winRect.maxX, y: winRect.minY + gap))
    winPath.line(to: NSPoint(x: winRect.maxX, y: winRect.maxY - r))
    winPath.appendArc(withCenter: NSPoint(x: winRect.maxX - r, y: winRect.maxY - r),
                       radius: r, startAngle: 0, endAngle: 90)
    winPath.line(to: NSPoint(x: winRect.minX + r, y: winRect.maxY))
    winPath.appendArc(withCenter: NSPoint(x: winRect.minX + r, y: winRect.maxY - r),
                       radius: r, startAngle: 90, endAngle: 180)
    winPath.line(to: NSPoint(x: winRect.minX, y: winRect.minY + r))
    winPath.appendArc(withCenter: NSPoint(x: winRect.minX + r, y: winRect.minY + r),
                       radius: r, startAngle: 180, endAngle: 270)
    winPath.line(to: NSPoint(x: winRect.maxX - gap, y: winRect.minY))
    winPath.lineWidth = lineWidth
    winPath.lineCapStyle = .round
    winPath.lineJoinStyle = .round
    NSColor.white.setStroke()
    winPath.stroke()

    // Flecha de redimensionar, justo en el hueco de la esquina inferior
    // derecha: mismo grosor que el marco, asta + una punta triangular
    // sólida que sale un poco más allá de la esquina de la ventana, sin
    // salirse del icono.
    let cornerPoint = NSPoint(x: winRect.maxX, y: winRect.minY)
    let diagX: CGFloat = 0.7071, diagY: CGFloat = -0.7071
    let shaftStart = NSPoint(x: winRect.maxX - gap * 0.55, y: winRect.minY + gap * 0.55)
    let tip = NSPoint(x: cornerPoint.x + size * 0.10 * diagX, y: cornerPoint.y + size * 0.10 * diagY)
    let shaftWidth = lineWidth
    let headLen = size * 0.15
    let headHalfWidth = size * 0.095
    let angle = atan2(tip.y - shaftStart.y, tip.x - shaftStart.x)
    let dx = cos(angle), dy = sin(angle)
    // Vector perpendicular al asta, para el ancho de la punta
    let px = -dy, py = dx

    // El asta termina donde arranca la punta, para que no se solapen.
    let headBase = NSPoint(x: tip.x - headLen * dx, y: tip.y - headLen * dy)

    let shaft = NSBezierPath()
    shaft.move(to: shaftStart)
    shaft.line(to: headBase)
    shaft.lineWidth = shaftWidth
    shaft.lineCapStyle = .round
    NSColor.white.setStroke()
    shaft.stroke()

    let head = NSBezierPath()
    head.move(to: tip)
    head.line(to: NSPoint(x: headBase.x + px * headHalfWidth, y: headBase.y + py * headHalfWidth))
    head.line(to: NSPoint(x: headBase.x - px * headHalfWidth, y: headBase.y - py * headHalfWidth))
    head.close()
    head.lineJoinStyle = .round
    head.lineWidth = size * 0.045
    NSColor.white.setFill()
    head.fill()
    NSColor.white.setStroke()
    head.stroke()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, size: CGFloat, to url: URL) {
    guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("No pude generar PNG")
    }
    try? data.write(to: url)
}

// Versión monocroma (plantilla) para el icono de la barra de menú: el
// mismo diseño que el icono de la app (marco de ventana con un hueco en
// la esquina inferior derecha + flecha de redimensionar), pero solo
// trazo/relleno negro, sin fondo — macOS la adapta sola a claro/oscuro.
func drawMenuBarIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let winRect = NSRect(x: 0, y: 0, width: size, height: size).insetBy(dx: size * 0.12, dy: size * 0.14)
    let r = size * 0.14
    let gap = size * 0.26
    let lineWidth = size * 0.1

    let winPath = NSBezierPath()
    winPath.move(to: NSPoint(x: winRect.maxX, y: winRect.minY + gap))
    winPath.line(to: NSPoint(x: winRect.maxX, y: winRect.maxY - r))
    winPath.appendArc(withCenter: NSPoint(x: winRect.maxX - r, y: winRect.maxY - r),
                       radius: r, startAngle: 0, endAngle: 90)
    winPath.line(to: NSPoint(x: winRect.minX + r, y: winRect.maxY))
    winPath.appendArc(withCenter: NSPoint(x: winRect.minX + r, y: winRect.maxY - r),
                       radius: r, startAngle: 90, endAngle: 180)
    winPath.line(to: NSPoint(x: winRect.minX, y: winRect.minY + r))
    winPath.appendArc(withCenter: NSPoint(x: winRect.minX + r, y: winRect.minY + r),
                       radius: r, startAngle: 180, endAngle: 270)
    winPath.line(to: NSPoint(x: winRect.maxX - gap, y: winRect.minY))
    winPath.lineWidth = lineWidth
    winPath.lineCapStyle = .round
    winPath.lineJoinStyle = .round
    NSColor.black.setStroke()
    winPath.stroke()

    let cornerPoint = NSPoint(x: winRect.maxX, y: winRect.minY)
    let diagX: CGFloat = 0.7071, diagY: CGFloat = -0.7071
    let shaftStart = NSPoint(x: winRect.maxX - gap * 0.55, y: winRect.minY + gap * 0.55)
    let tip = NSPoint(x: cornerPoint.x + size * 0.07 * diagX, y: cornerPoint.y + size * 0.07 * diagY)
    let headLen = size * 0.17
    let headHalfWidth = size * 0.1
    let angle = atan2(tip.y - shaftStart.y, tip.x - shaftStart.x)
    let dx = cos(angle), dy = sin(angle)
    let px = -dy, py = dx
    let headBase = NSPoint(x: tip.x - headLen * dx, y: tip.y - headLen * dy)

    let shaft = NSBezierPath()
    shaft.move(to: shaftStart)
    shaft.line(to: headBase)
    shaft.lineWidth = lineWidth
    shaft.lineCapStyle = .round
    NSColor.black.setStroke()
    shaft.stroke()

    let head = NSBezierPath()
    head.move(to: tip)
    head.line(to: NSPoint(x: headBase.x + px * headHalfWidth, y: headBase.y + py * headHalfWidth))
    head.line(to: NSPoint(x: headBase.x - px * headHalfWidth, y: headBase.y - py * headHalfWidth))
    head.close()
    head.lineJoinStyle = .round
    head.lineWidth = size * 0.07
    NSColor.black.setFill()
    head.fill()
    NSColor.black.setStroke()
    head.stroke()

    image.unlockFocus()
    image.isTemplate = true
    return image
}

if CommandLine.arguments.count > 2, CommandLine.arguments[1] == "--menubar" {
    let outDir = URL(fileURLWithPath: CommandLine.arguments[2])
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
    savePNG(drawMenuBarIcon(size: 18), size: 18, to: outDir.appendingPathComponent("MenuBarIcon.png"))
    savePNG(drawMenuBarIcon(size: 36), size: 36, to: outDir.appendingPathComponent("MenuBarIcon@2x.png"))
    print("Icono de barra de menú generado en \(outDir.path)")
    exit(0)
}

let args = CommandLine.arguments
guard args.count > 1 else {
    print("Uso: generate_icon.swift <carpeta-iconset-destino>")
    exit(1)
}
let outDir = URL(fileURLWithPath: args[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, px) in sizes {
    let img = drawIcon(size: px)
    savePNG(img, size: px, to: outDir.appendingPathComponent("\(name).png"))
}
print("Iconset generado en \(outDir.path)")
