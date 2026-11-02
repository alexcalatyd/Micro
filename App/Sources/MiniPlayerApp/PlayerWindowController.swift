import AppKit
import SwiftUI
import WebKit

final class PlayerWindowController: NSWindowController, NSWindowDelegate, WKNavigationDelegate {
    private let webView: WKWebView
    private let url: URL
    private let isYouTube: Bool
    private let youTubeVideoID: String?
    private let parsedYouTube: YouTubeURLHelper.Parsed?
    private let startSeconds: Double?
    private let originTab: BrowserTab?
    private var didApplyInitialSeek = false
    private var keyMonitor: Any?
    private var settingsPopover: NSPopover?
    private var gearButton: NSButton!
    private var resizeHandle: ResizeHandleView!
    private var hideControlsTimer: Timer?
    // Tras cuántos segundos sin ratón encima se esconden ⚙️ y la esquina de redimensionar.
    private static let hideControlsDelay: TimeInterval = 2.5

    /// Avisa a quien creó este controlador de que la ventana se cerró, para
    /// que pueda quitarlo de su lista (evita acumular controladores muertos).
    var onWindowClosed: (() -> Void)?

    // Muchos sitios (Netflix sobre todo) hacen detección de navegador agresiva
    // y tratan distinto a WKWebView si no se identifica como Safari real.
    private static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
    private static let dragHandleHeight: CGFloat = 26

    init(url: URL, startSeconds: Double? = nil, originTab: BrowserTab? = nil, centerOnScreen: Bool = false) {
        self.url = url
        self.startSeconds = startSeconds
        self.originTab = originTab
        var parsedYouTube = YouTubeURLHelper.parse(url)
        self.isYouTube = parsedYouTube != nil
        self.youTubeVideoID = parsedYouTube?.videoID

        // El minuto por el que iba la pestaña de origen (recién capturado vía
        // JS al abrir el mini reproductor) manda sobre cualquier otra cosa;
        // si no lo hay, retoma por dónde quedó la última vez que se vio este
        // mismo vídeo en el propio mini reproductor.
        if let parsed = parsedYouTube, parsed.startSeconds == 0 {
            if let startSeconds {
                parsedYouTube = YouTubeURLHelper.Parsed(videoID: parsed.videoID, startSeconds: Int(startSeconds))
            } else if let saved = PlayerSettings.shared.lastPosition(forVideoID: parsed.videoID) {
                parsedYouTube = YouTubeURLHelper.Parsed(videoID: parsed.videoID, startSeconds: Int(saved))
            }
        }
        self.parsedYouTube = parsedYouTube

        let config = WKWebViewConfiguration()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        // Store de cookies persistente: una vez inicies sesión (Netflix, etc.)
        // dentro de esta ventana, se recuerda entre reinicios de la app.
        // (No puede compartir cookies con Brave/Safari — son sandboxes distintos).
        config.websiteDataStore = WKWebsiteDataStore.default()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = Self.safariUserAgent
        self.webView = webView

        let settings = PlayerSettings.shared
        let defaultSize = PlayerSettings.sizePresets[1].size // Mediana, 16:9
        let initialFrame = settings.lastFrame ?? NSRect(x: 100, y: 100, width: defaultSize.width, height: defaultSize.height)

        let panel = FloatingPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        if centerOnScreen {
            panel.center() // p.ej. el rickroll de bienvenida: siempre en mitad de la pantalla
        }
        panel.isReleasedWhenClosed = false
        panel.level = settings.windowLevel.nsWindowLevel
        // .managed + .participatesInCycle: sin esto, Mission Control excluye
        // por defecto cualquier ventana con nivel .floating (como hacen los
        // paneles flotantes de apps tipo Photoshop).
        panel.collectionBehavior = [.managed, .participatesInCycle]
        panel.hidesOnDeactivate = false // <- esto evitaba que "desapareciera" al pulsar otra app
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.minSize = NSSize(width: 240, height: 135)
        panel.contentAspectRatio = NSSize(width: 16, height: 9) // al redimensionar a mano, mantiene 16:9

        super.init(window: panel)

        guard let content = panel.contentView else { fatalError("panel sin contentView") }
        content.wantsLayer = true

        let dragHandle = DragHandleView(frame: NSRect(
            x: 0,
            y: content.bounds.height - Self.dragHandleHeight,
            width: content.bounds.width,
            height: Self.dragHandleHeight
        ))
        dragHandle.autoresizingMask = [.width, .minYMargin]

        webView.frame = content.bounds
        webView.autoresizingMask = [.width, .height]
        webView.wantsLayer = true
        webView.layer?.cornerRadius = 14
        webView.layer?.masksToBounds = true

        content.addSubview(webView)
        content.addSubview(dragHandle) // por encima del webview, solo ocupa la franja superior

        let gearButton = NSButton(frame: NSRect(
            x: content.bounds.width - 26,
            y: content.bounds.height - Self.dragHandleHeight + 2,
            width: 22, height: 22
        ))
        gearButton.autoresizingMask = [.minXMargin, .minYMargin]
        gearButton.title = ""
        gearButton.image = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "Ajustes")
        gearButton.imagePosition = .imageOnly
        gearButton.isBordered = false
        gearButton.bezelStyle = .regularSquare
        gearButton.contentTintColor = .white // siempre visible encima de cualquier vídeo
        gearButton.wantsLayer = true
        gearButton.layer?.shadowColor = NSColor.black.cgColor
        gearButton.layer?.shadowOpacity = 0.8
        gearButton.layer?.shadowRadius = 2
        gearButton.layer?.shadowOffset = .zero
        gearButton.target = self
        gearButton.action = #selector(showSettingsMenu(_:))
        gearButton.alphaValue = 0 // oculto hasta que el ratón pase por encima de la ventana
        content.addSubview(gearButton) // por encima de todo, intercepta su propio clic
        self.gearButton = gearButton

        let resizeHandle = ResizeHandleView(frame: NSRect(x: content.bounds.width - 20, y: 4, width: 16, height: 16))
        resizeHandle.autoresizingMask = [.minXMargin, .maxYMargin] // se queda fija en la esquina inferior derecha
        resizeHandle.alphaValue = 0 // oculto hasta que el ratón pase por encima de la ventana
        content.addSubview(resizeHandle)
        self.resizeHandle = resizeHandle

        // Solo se ven ⚙️ y la esquina de redimensionar mientras el ratón
        // está sobre la ventana; se esconden solos a los pocos segundos de
        // quitarlo. .inVisibleRect mantiene el área de seguimiento ajustada
        // sola al tamaño real aunque la ventana se redimensione.
        content.addTrackingArea(NSTrackingArea(
            rect: content.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))

        panel.delegate = self
        webView.navigationDelegate = self

        if let parsed = parsedYouTube {
            webView.loadHTMLString(YouTubeURLHelper.wrapperHTML(parsed: parsed), baseURL: URL(string: "https://example.com"))
        } else {
            webView.load(URLRequest(url: url))
        }

        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(webView)
        installKeyboardShortcuts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) no soportado")
    }

    // MARK: - Atajos de teclado (seek ±10s, espacio = play/pause)

    private func installKeyboardShortcuts() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }

            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "r": self.reloadPage(); return nil
                case "w": self.close(); return nil
                default: return event
                }
            }

            switch event.keyCode {
            case 123: self.seek(by: -10); return nil // flecha izquierda
            case 124: self.seek(by: 10); return nil  // flecha derecha
            case 49: self.togglePlayPause(); return nil // espacio
            default: return event
            }
        }
    }

    private func seek(by seconds: Int) {
        if isYouTube {
            webView.evaluateJavaScript("window.__miniplayerSeek && window.__miniplayerSeek(\(seconds));")
        } else {
            let js = "(function(){var v=document.querySelector('video'); if(v) v.currentTime = Math.max(0, v.currentTime + (\(seconds)));})();"
            webView.evaluateJavaScript(js)
        }
    }

    private func togglePlayPause() {
        if isYouTube {
            webView.evaluateJavaScript("window.__miniplayerToggle && window.__miniplayerToggle();")
        } else {
            let js = "(function(){var v=document.querySelector('video'); if(v){ v.paused ? v.play() : v.pause(); }})();"
            webView.evaluateJavaScript(js)
        }
    }

    // MARK: - Mostrar/ocultar controles (⚙️ + esquina de redimensionar) al pasar el ratón

    // NSTrackingArea llama a estos dos métodos sobre su `owner` (este
    // controlador) al entrar/salir del área — no son overrides de NSView.
    override func mouseEntered(with event: NSEvent) {
        hideControlsTimer?.invalidate()
        setControlsVisible(true)
    }

    override func mouseExited(with event: NSEvent) {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: Self.hideControlsDelay, repeats: false) { [weak self] _ in
            self?.setControlsVisible(false)
        }
    }

    private func setControlsVisible(_ visible: Bool) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            gearButton.animator().alphaValue = visible ? 1 : 0
            resizeHandle.animator().alphaValue = visible ? 1 : 0
        }
    }

    // MARK: - Panel de ajustes (⚙️ dentro de la ventana)

    @objc private func showSettingsMenu(_ sender: NSButton) {
        let popover = NSPopover()
        popover.behavior = .transient
        let view = SettingsPanelView(
            level: PlayerSettings.shared.windowLevel,
            language: PlayerSettings.shared.language,
            onSelectLevel: { [weak self] level in
                PlayerSettings.shared.windowLevel = level
                self?.apply(level: level)
            },
            onSelectSize: { [weak self] size in
                self?.apply(size: size)
            },
            onSelectLanguage: { language in
                PlayerSettings.shared.language = language
            },
            onReload: { [weak self] in
                self?.reloadPage()
                self?.settingsPopover?.close()
            },
            onClose: { [weak self] in
                self?.settingsPopover?.close()
                self?.close()
            }
        )
        let hosting = NSHostingController(rootView: view)
        popover.contentViewController = hosting
        hosting.view.layoutSubtreeIfNeeded()
        popover.contentSize = hosting.view.fittingSize
        settingsPopover = popover
        NSApp.activate(ignoringOtherApps: true) // si no, puede salir "apagado" hasta el primer clic
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }

    @objc func reloadPage() {
        // webView.reload() no sirve aquí: el contenido se cargó con
        // loadHTMLString (no una URL real), y reload() acaba navegando al
        // baseURL de ejemplo en vez de recargar el reproductor.
        if let parsed = parsedYouTube {
            webView.loadHTMLString(YouTubeURLHelper.wrapperHTML(parsed: parsed), baseURL: URL(string: "https://example.com"))
        } else {
            webView.reload()
        }
    }

    /// Permiten que ajustes externos (ej. el icono de la barra de menú) actualicen esta ventana ya abierta.
    func apply(level: WindowLevelPreference) {
        window?.level = level.nsWindowLevel
    }

    func apply(size: NSSize) {
        guard var frame = window?.frame else { return }
        frame.size = size
        window?.setFrame(frame, display: true, animate: true)
        PlayerSettings.shared.lastFrame = frame
    }

    // MARK: - Delegados

    func windowWillClose(_ notification: Notification) {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        hideControlsTimer?.invalidate()
        pauseAndSavePosition {
            // Parar el audio/vídeo de verdad: stopLoading() no basta, el <video>
            // sigue sonando si no se le manda pause() o se descarga la página.
            self.webView.stopLoading()
            self.webView.loadHTMLString("", baseURL: nil)
        }
        onWindowClosed?()
    }

    /// Igual que cerrar la ventana (pausa el vídeo, guarda por dónde iba),
    /// pero sin tocar la ventana ni el array de `players`: se usa cuando la
    /// app entera se está cerrando (Cmd+Q / "Salir de Micro"), para dar
    /// tiempo a que WebKit termine de escribir en disco las cookies que se
    /// acaban de fijar (p. ej. justo tras iniciar sesión en Netflix) antes
    /// de que el proceso muera de verdad. Sin esto, `NSApp.terminate`
    /// puede matar el proceso de WebKit a mitad de esa escritura.
    func prepareForTermination(completion: @escaping () -> Void) {
        pauseAndSavePosition(completion)
    }

    /// Lee por dónde iba el vídeo (para YouTube, por ID) y lo pausa de
    /// verdad vía JS, antes de avisar con `then` de que ya se puede seguir.
    private func pauseAndSavePosition(_ then: @escaping () -> Void) {
        let js = isYouTube
            ? "window.__miniplayerCurrentTimeAndPause && window.__miniplayerCurrentTimeAndPause();"
            : "(function(){ var v = document.querySelector('video'); var t = v ? v.currentTime : 0; if (v) v.pause(); return t; })();"

        webView.evaluateJavaScript(js) { result, _ in
            if let seconds = result as? Double, seconds > 0 {
                if self.isYouTube, let videoID = self.youTubeVideoID {
                    PlayerSettings.shared.setLastPosition(seconds, forVideoID: videoID)
                }
                // Si este mini reproductor vino de una pestaña del navegador,
                // la dejamos en el mismo minuto al cerrar, para poder seguir
                // ahí si se vuelve a esa pestaña (requiere "Allow JavaScript
                // from Apple Events" activado en el navegador; si no, no hace nada).
                if let originTab = self.originTab {
                    BrowserTabSource.seek(originTab, toSeconds: seconds)
                }
            }
            then()
        }
    }

    func windowDidMove(_ notification: Notification) {
        if let frame = window?.frame {
            PlayerSettings.shared.lastFrame = frame
        }
    }

    func windowDidResize(_ notification: Notification) {
        if let frame = window?.frame {
            PlayerSettings.shared.lastFrame = frame
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !isYouTube, !didApplyInitialSeek, let startSeconds, startSeconds > 0 else { return }
        didApplyInitialSeek = true
        // Sitios tipo Netflix cargan el <video> de forma diferida (SPA), así
        // que reintentamos un rato hasta que exista antes de saltar al minuto.
        applyInitialSeek(toSeconds: startSeconds, attemptsLeft: 20)
    }

    private func applyInitialSeek(toSeconds seconds: Double, attemptsLeft: Int) {
        guard attemptsLeft > 0 else { return }
        let js = "(function(){var v=document.querySelector('video'); if(v){ v.currentTime = \(seconds); return true; } return false;})();"
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self else { return }
            if (result as? Bool) != true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.applyInitialSeek(toSeconds: seconds, attemptsLeft: attemptsLeft - 1)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("MiniPlayer: fallo de navegación -> \(error)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("MiniPlayer: fallo tras cargar -> \(error)")
    }
}
