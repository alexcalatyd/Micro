import AppKit

/// Franja superior invisible para poder arrastrar la ventana con el ratón.
/// El WKWebView se queda con todos los demás clics (play, barra de progreso, etc).
final class DragHandleView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
