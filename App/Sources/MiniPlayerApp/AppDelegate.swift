import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var statusPopover: NSPopover?
    private var tabPickerPopover: NSPopover?
    private var players: [PlayerWindowController] = []
    private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("MiniPlayer: lanzado, pid \(ProcessInfo.processInfo.processIdentifier)")
        // .accessory: sin icono en el Dock y sin aparecer en Cmd+Tab (así es
        // como macOS define una app accesoria). Mission Control (F3) sigue
        // mostrando la ventana porque eso lo controla collectionBehavior,
        // no la política de activación.
        NSApp.setActivationPolicy(.accessory)
        clearInstallerCustomIconIfNeeded()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = Self.loadMenuBarIcon()
            button.target = self
            button.action = #selector(toggleStatusPopover(_:))
        }

        if !PlayerSettings.shared.hasCompletedOnboarding {
            showOnboarding()
        }
    }

    // Al salir de Micro (Cmd+Q / "Salir de Micro"), damos un respiro a
    // WebKit para que termine de escribir en disco las cookies recién
    // fijadas (p. ej. justo tras iniciar sesión en Netflix) antes de matar
    // el proceso. Sin esto, el login podía "no guardarse" si se cerraba la
    // app enseguida: el proceso de WebKit moría a mitad de esa escritura.
    private var isTerminating = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !players.isEmpty else { return .terminateNow }

        let group = DispatchGroup()
        for player in players {
            group.enter()
            player.prepareForTermination { group.leave() }
        }

        func replyOnce() {
            guard !isTerminating else { return }
            isTerminating = true
            NSApp.reply(toApplicationShouldTerminate: true)
        }

        group.notify(queue: .main, execute: replyOnce)
        // Red de seguridad: si algo se queda colgado, no bloqueamos el cierre para siempre.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: replyOnce)

        return .terminateLater
    }

    // MARK: - Icono personalizado del instalador (solo primer arranque)

    /// La copia de Micro.app dentro del .dmg lleva un icono personalizado
    /// fijo (ver make_dmg.sh / Scripts/set_custom_icon.swift) para que se
    /// vea igual en claro y en oscuro dentro del instalador. Ese icono
    /// personalizado sobrevive al arrastrar la app a Applications (Finder
    /// copia también ese atributo) — así que, ya instalada, la propia app
    /// se lo quita a sí misma en su primer arranque, para volver a seguir
    /// el icono normal (adaptado al tema) como cualquier otra app.
    private func clearInstallerCustomIconIfNeeded() {
        // Idempotente y barato: si no tenía icono personalizado, no hace nada.
        NSWorkspace.shared.setIcon(nil, forFile: Bundle.main.bundlePath, options: [])
    }

    // MARK: - Guía de bienvenida

    private func showOnboarding() {
        // El onboarding siempre arranca en inglés por defecto, con opción de
        // cambiar a español desde su propio selector — independiente del
        // idioma que tenga elegido el resto de la app.
        let controller = OnboardingWindowController(
            language: .en,
            onFinish: { [weak self] in
                PlayerSettings.shared.hasCompletedOnboarding = true
                // Pequeño guiño: terminar la guía abre un mini reproductor
                // con el clásico rickroll, como primer vídeo de ejemplo.
                // startSeconds: 0 fuerza que arranque desde el principio
                // siempre, aunque el usuario ya lo haya visto antes en Micro
                // (si no, retomaría por el minuto guardado de la vez anterior).
                let rickroll = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!
                self?.openPlayer(for: rickroll, startSeconds: 0, centerOnScreen: true)
            }
        )
        onboardingWindowController = controller
        controller.show()
    }

    /// Icono propio de la barra de menú (plantilla monocroma, combina @1x/@2x
    /// en una sola NSImage para que macOS elija la resolución correcta).
    private static func loadMenuBarIcon() -> NSImage? {
        guard let path1x = Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
              let path2x = Bundle.main.path(forResource: "MenuBarIcon@2x", ofType: "png"),
              let rep1x = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: path1x))),
              let rep2x = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: path2x))) else {
            return NSImage(systemSymbolName: "play.circle.fill", accessibilityDescription: "Micro")
        }
        rep1x.size = NSSize(width: 18, height: 18)
        rep2x.size = NSSize(width: 18, height: 18)
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.addRepresentation(rep1x)
        image.addRepresentation(rep2x)
        image.isTemplate = true
        return image
    }

    // MARK: - Panel de la barra de menú

    @objc private func toggleStatusPopover(_ sender: NSStatusBarButton) {
        if let popover = statusPopover, popover.isShown {
            popover.close()
            return
        }

        let popover = NSPopover()
        popover.behavior = .transient
        let view = StatusBarPanelView(
            level: PlayerSettings.shared.windowLevel,
            language: PlayerSettings.shared.language,
            onOpenTabPicker: { [weak self] in self?.showTabPickerGrid(from: sender) },
            onSelectLevel: { [weak self] level in
                PlayerSettings.shared.windowLevel = level
                self?.players.forEach { $0.apply(level: level) }
            },
            onSelectSize: { [weak self] size in
                self?.players.forEach { $0.apply(size: size) }
            },
            onSelectLanguage: { language in
                PlayerSettings.shared.language = language
            },
            onReloadActive: { [weak self] in
                self?.reloadActive()
                self?.statusPopover?.close()
            },
            onCloseActive: { [weak self] in
                self?.closeActive()
                self?.statusPopover?.close()
            },
            onShowGuide: { [weak self] in
                self?.statusPopover?.close()
                self?.showOnboarding()
            },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        let hosting = NSHostingController(rootView: view)
        popover.contentViewController = hosting
        hosting.view.layoutSubtreeIfNeeded()
        popover.contentSize = hosting.view.fittingSize
        statusPopover = popover
        NSApp.activate(ignoringOtherApps: true) // si no, el panel sale "apagado" (app inactiva) hasta el primer clic
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    // MARK: - Selector visual de pestañas (previews en rejilla)

    private func showTabPickerGrid(from view: NSView) {
        statusPopover?.close()

        let tabs = BrowserTabSource.fetchAllTabs()
        let popover = NSPopover()
        popover.behavior = .transient
        let gridView = TabPickerGridView(tabs: tabs, onSelect: { [weak self] tab in
            let startSeconds = BrowserTabSource.pauseVideoAndCaptureTime(in: tab)
            self?.openPlayer(for: tab.url, startSeconds: startSeconds, originTab: tab)
            self?.tabPickerPopover?.close()
        })
        let hosting = NSHostingController(rootView: gridView)
        popover.contentViewController = hosting
        hosting.view.layoutSubtreeIfNeeded()
        popover.contentSize = hosting.view.fittingSize
        tabPickerPopover = popover
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    private func reloadActive() {
        frontmostPlayer()?.reloadPage()
    }

    private func closeActive() {
        frontmostPlayer()?.close()
    }

    private func frontmostPlayer() -> PlayerWindowController? {
        players.first(where: { $0.window?.isKeyWindow == true }) ?? players.last
    }

    // Método estándar de AppKit para recibir aperturas de esquema de URL personalizado
    // (equivalente al de iOS). Se llama cuando algo hace `open micro://...`.
    func application(_ application: NSApplication, open urls: [URL]) {
        print("MiniPlayer: URLs recibidas -> \(urls)")
        for url in urls {
            handleIncoming(url: url)
        }
    }

    private func handleIncoming(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let targetString = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let targetURL = URL(string: targetString) else {
            print("MiniPlayer: no pude extraer el parámetro url de \(url)")
            return
        }
        openPlayer(for: targetURL)
    }

    private func openPlayer(for url: URL, startSeconds: Double? = nil, originTab: BrowserTab? = nil, centerOnScreen: Bool = false) {
        let controller = PlayerWindowController(url: url, startSeconds: startSeconds, originTab: originTab, centerOnScreen: centerOnScreen)
        controller.onWindowClosed = { [weak self, weak controller] in
            guard let self, let controller else { return }
            self.players.removeAll { $0 === controller }
        }
        players.append(controller)
        NSApp.activate(ignoringOtherApps: true)
    }
}
