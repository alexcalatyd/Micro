import AppKit

/// Esquina de agarre visible (abajo a la derecha) para redimensionar a mano.
/// Las ventanas "borderless" tienen un margen de agarre en los bordes
/// minúsculo por defecto; esto da una zona cómoda y clara donde arrastrar.
final class ResizeHandleView: NSImageView {
    private var initialMouseLocation: NSPoint = .zero
    private var initialWindowFrame: NSRect = .zero

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Redimensionar")
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

        var newWidth = max(window.minSize.width, initialWindowFrame.width + dx)
        var newHeight = newWidth * 9 / 16 // mantiene la proporción 16:9
        if newHeight < window.minSize.height {
            newHeight = window.minSize.height
            newWidth = newHeight * 16 / 9
        }

        var frame = initialWindowFrame
        frame.size = NSSize(width: newWidth, height: newHeight)
        frame.origin.y = initialWindowFrame.maxY - newHeight // crece hacia abajo, no hacia arriba
        window.setFrame(frame, display: true)
    }
}
