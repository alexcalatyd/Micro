#!/usr/bin/swift
import AppKit

// Fondo del DMG con la misma estética que el icono de la app: azul plano,
// blanco como único color de acento, flecha de redimensionar a juego, sin
// adornos sueltos (nada de naranja). Se genera a 1x y 2x para que se vea
// nítido en pantallas Retina (dmgbuild combina ambas automáticamente si
// encuentra un archivo "nombre@2x.png" junto al base).

let widthPt: CGFloat = 600
let heightPt: CGFloat = 420
let iconRowYPt: CGFloat = heightPt - 230 // coincide con la posición de los iconos en Finder

let blue = NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.93, alpha: 1.0)
let white = NSColor.white

func roundedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if let roundedDescriptor = base.fontDescriptor.withDesign(.rounded),
       let rounded = NSFont(descriptor: roundedDescriptor, size: size) {
        return rounded
    }
    return base
}

func draw(scale: CGFloat) -> NSBitmapImageRep {
    let width = widthPt * scale
    let height = heightPt * scale

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width),
        pixelsHigh: Int(height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("no pude crear el bitmap")
    }
    bitmap.size = NSSize(width: widthPt, height: heightPt)

    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: scale, y: scale)
    context.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: widthPt, height: heightPt)
    blue.setFill()
    rect.fill()

    // Sombra suave detrás de la posición del icono de Micro.app: al ser
    // del mismo azul que el fondo, sin esto no se distingue que hay un
    // icono ahí. Se dibuja un cuadrado redondeado del mismo azul (invisible
    // por sí solo) pero con sombra activada en el contexto, para que solo
    // se note el halo oscuro alrededor, no una forma visible.
    let iconCenter = NSPoint(x: 160, y: iconRowYPt)
    let shadowChip = NSBezierPath(
        roundedRect: NSRect(x: iconCenter.x - 64, y: iconCenter.y - 64, width: 128, height: 128),
        xRadius: 28, yRadius: 28
    )
    context.cgContext.saveGState()
    context.cgContext.setShadow(
        offset: CGSize(width: 0, height: -3),
        blur: 22,
        color: NSColor.black.withAlphaComponent(0.45).cgColor
    )
    blue.setFill()
    shadowChip.fill()
    context.cgContext.restoreGState()

    // Título, misma tipografía redondeada y peso que transmite el estilo
    // "app moderna" del resto de Micro.
    let title = "Micro"
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(size: 40, weight: .bold),
        .foregroundColor: white
    ]
    let titleSize = title.size(withAttributes: titleAttrs)
    title.draw(at: NSPoint(x: (widthPt - titleSize.width) / 2, y: heightPt - 78), withAttributes: titleAttrs)

    let subtitle = "Mini floating player"
    let subtitleAttrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(size: 15, weight: .medium),
        .foregroundColor: white.withAlphaComponent(0.75)
    ]
    let subtitleSize = subtitle.size(withAttributes: subtitleAttrs)
    subtitle.draw(at: NSPoint(x: (widthPt - subtitleSize.width) / 2, y: heightPt - 102), withAttributes: subtitleAttrs)

    // Flecha entre las dos posiciones de icono: mismo lenguaje visual que
    // el icono de la app (asta + punta triangular, blanco sobre azul).
    let startX: CGFloat = 228
    let endX: CGFloat = 372
    let shaftWidth: CGFloat = 4
    let headLen: CGFloat = 20
    let headHalfWidth: CGFloat = 11

    let shaft = NSBezierPath()
    shaft.move(to: NSPoint(x: startX, y: iconRowYPt))
    shaft.line(to: NSPoint(x: endX - headLen, y: iconRowYPt))
    shaft.lineWidth = shaftWidth
    shaft.lineCapStyle = .round
    white.setStroke()
    shaft.stroke()

    let head = NSBezierPath()
    head.move(to: NSPoint(x: endX, y: iconRowYPt))
    head.line(to: NSPoint(x: endX - headLen, y: iconRowYPt + headHalfWidth))
    head.line(to: NSPoint(x: endX - headLen, y: iconRowYPt - headHalfWidth))
    head.close()
    head.lineJoinStyle = .round
    white.setFill()
    head.fill()

    // Texto de instrucción debajo de los iconos
    let text = "Drag Micro to the Applications folder"
    let attrs: [NSAttributedString.Key: Any] = [
        .font: roundedFont(size: 14, weight: .medium),
        .foregroundColor: white.withAlphaComponent(0.85)
    ]
    let textSize = text.size(withAttributes: attrs)
    text.draw(at: NSPoint(x: (widthPt - textSize.width) / 2, y: 68), withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func save(_ bitmap: NSBitmapImageRep, to path: String) {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("no pude generar el PNG")
    }
    try! data.write(to: URL(fileURLWithPath: path))
}

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg_background.png"
let outPath2x: String = {
    let url = URL(fileURLWithPath: outPath)
    let name = url.deletingPathExtension().lastPathComponent
    let ext = url.pathExtension
    return url.deletingLastPathComponent().appendingPathComponent("\(name)@2x.\(ext)").path
}()

save(draw(scale: 1), to: outPath)
save(draw(scale: 2), to: outPath2x)
print("Fondo del DMG generado en \(outPath) y \(outPath2x)")
