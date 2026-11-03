import AppKit

/// Esquina de agarre visible para redimensionar a mano. Hay una en cada
/// esquina de la ventana: todas funcionan igual, cada una anclando la
/// esquina opuesta (como en cualquier ventana normal de macOS).
/// Las ventanas "borderless" tienen un margen de agarre en los bordes
/// minúsculo por defecto; esto da una zona cómoda y clara donde arrastrar.
final class ResizeHandleView: NSImageView {
    enum Corner {
        case bottomRight, bottomLeft, topRight, topLeft

        /// La esquina queda fija al arrastrar: si agarramos por la izquierda,
        /// el ancho crece hacia la izquierda (dx invertido), y si agarramos
        /// por arriba, la altura crece hacia arriba.
        var isLeft: Bool { self == .bottomLeft || self == .topLeft }
        var isTop: Bool { self == .topRight || self == .topLeft }

        /// Las diagonales ↖↘ y ↗↙, para que la flecha apunte hacia fuera.
        var symbolName: String {
            switch self {
            case .bottomRight, .topLeft: return "arrow.up.left.and.arrow.down.right"
            case .bottomLeft, .topRight: return "arrow.up.right.and.arrow.down.left"
            }
        }
    }

    let corner: Corner
    private var initialMouseLocation: NSPoint = .zero
    private var initialWindowFrame: NSRect = .zero

    init(frame frameRect: NSRect, corner: Corner) {
        self.corner = corner
        super.init(frame: frameRect)
        image = NSImage(systemSymbolName: corner.symbolName, accessibilityDescription: "Redimensionar")
        imageScaling = .scaleProportionallyUpOrDown
        contentTintColor = .white
        wantsLayer = true
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.8
        layer?.shadowRadius = 2
        layer?.shadowOffset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no soportado")
    }

    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowFrame = window?.frame ?? .zero
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let current = NSEvent.mouseLocation
        let dx = current.x - initialMouseLocation.x

        var newWidth = max(window.minSize.width, initialWindowFrame.width + (corner.isLeft ? -dx : dx))
        var newHeight = newWidth * 9 / 16 // mantiene la proporción 16:9
        if newHeight < window.minSize.height {
            newHeight = window.minSize.height
            newWidth = newHeight * 16 / 9
        }

        var frame = initialWindowFrame
        frame.size = NSSize(width: newWidth, height: newHeight)
        // La esquina opuesta a la que se agarra se queda clavada en su sitio.
        frame.origin.x = corner.isLeft ? initialWindowFrame.maxX - newWidth : initialWindowFrame.minX
        frame.origin.y = corner.isTop ? initialWindowFrame.minY : initialWindowFrame.maxY - newHeight
        window.setFrame(frame, display: true)
    }
}
