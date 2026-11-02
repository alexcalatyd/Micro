import AppKit
import SwiftUI

/// Ventana normal (con barra de título, no un panel flotante borderless)
/// para la guía de bienvenida. Se muestra sola la primera vez que se abre
/// la app, y también se puede volver a abrir a mano desde el panel de la
/// barra de menú.
final class OnboardingWindowController: NSWindowController {
    convenience init(language: AppLanguage, onFinish: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = SettingsStrings.t(.appName, language)
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)

        let view = OnboardingView(language: language, onFinish: { [weak self] in
            onFinish()
            self?.close()
        })
        let hosting = NSHostingController(rootView: view)
        window.contentViewController = hosting
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
