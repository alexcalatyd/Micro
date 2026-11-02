import AppKit

/// Panel flotante que SÍ acepta foco de teclado (para poder escribir en la
/// barra de búsqueda de YouTube) aunque sea un panel sin bordes.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
