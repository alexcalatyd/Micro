import AppKit

struct BrowserTab: Identifiable {
    let browserAppName: String
    let windowIndex: Int
    let tabIndex: Int
    let title: String
    let url: URL
    let isActive: Bool

    var id: String { "\(browserAppName)-\(windowIndex)-\(tabIndex)" }
}

/// Lee las pestañas abiertas de los navegadores soportados vía AppleScript —
/// la forma estándar y soportada en macOS para que una app externa consulte
/// pestañas de un navegador (la primera vez por navegador, macOS pide
/// permiso de Automatización). Así funciona con cualquier navegador
/// scriptable, sin depender de una extensión instalada.
enum BrowserTabSource {
    private static let chromiumBrowsers = [
        "Brave Browser", "Google Chrome", "Microsoft Edge", "Vivaldi", "Opera"
    ]

    static func fetchAllTabs() -> [BrowserTab] {
        var tabs: [BrowserTab] = []
        for appName in chromiumBrowsers where isRunning(appName) {
            tabs += fetchChromiumTabs(appName: appName)
        }
        if isRunning("Safari") {
            tabs += fetchSafariTabs()
        }
        return tabs
    }

    /// Pausa el vídeo de esa pestaña y, si puede, devuelve el minuto exacto
    /// por el que iba (para arrancar el mini reproductor justo ahí). Primero
    /// intenta vía JavaScript (si el usuario tiene activado "Allow
    /// JavaScript from Apple Events" en el navegador, que NO viene activado
    /// por defecto — sin esto no hay forma de leer el minuto exacto). Si eso
    /// falla — el caso normal, sin tocar nada en el navegador — cae
    /// automáticamente a activar esa pestaña y mandarle la tecla espacio
    /// (atajo universal de pausa) vía Accesibilidad, que solo pide el
    /// permiso de sistema estándar la primera vez; en ese caso no hay
    /// minuto exacto que devolver.
    @discardableResult
    static func pauseVideoAndCaptureTime(in tab: BrowserTab) -> Double? {
        if let seconds = pauseViaJavaScript(tab) { return seconds }
        pauseViaKeystroke(tab)
        return nil
    }

    /// Manda el vídeo de esa pestaña (sin activarla ni tocar el foco) a un
    /// minuto concreto, para que al volver al navegador siga por donde
    /// quedó el mini reproductor. Solo funciona con "Allow JavaScript from
    /// Apple Events" activado; si no, no hace nada (no hay alternativa sin
    /// JS para esto).
    static func seek(_ tab: BrowserTab, toSeconds seconds: Double) {
        let js = "document.querySelectorAll('video').forEach(function(v){v.currentTime = \(seconds);});"
        _ = runJavaScript(js, in: tab)
    }

    /// Pausa y devuelve `video.currentTime` del primer <video> de la
    /// pestaña, o `nil` si no se pudo ejecutar JavaScript en ella.
    private static func pauseViaJavaScript(_ tab: BrowserTab) -> Double? {
        let js = "(function(){var v=document.querySelector('video'); var t=v?v.currentTime:0; if(v) v.pause(); return t;})();"
        guard let resultString = runJavaScript(js, in: tab) else { return nil }
        return Double(resultString)
    }

    /// Ejecuta JS en esa pestaña vía AppleScript y devuelve el resultado
    /// como texto, o `nil` si falló (típicamente porque el navegador no
    /// tiene activado "Allow JavaScript from Apple Events").
    private static func runJavaScript(_ js: String, in tab: BrowserTab) -> String? {
        let escaped = js.replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        if tab.browserAppName == "Safari" {
            script = """
            tell application "Safari"
                do JavaScript "\(escaped)" in tab \(tab.tabIndex) of window \(tab.windowIndex)
            end tell
            """
        } else {
            script = """
            tell application "\(tab.browserAppName)"
                execute tab \(tab.tabIndex) of window \(tab.windowIndex) javascript "\(escaped)"
            end tell
            """
        }
        var errorDict: NSDictionary?
        let result = NSAppleScript(source: script)?.executeAndReturnError(&errorDict)
        if let errorDict {
            print("BrowserTabSource: JS no disponible en \(tab.browserAppName) (¿falta activar 'Allow JavaScript from Apple Events'?) -> \(errorDict)")
            return nil
        }
        return result?.stringValue
    }

    private static func pauseViaKeystroke(_ tab: BrowserTab) {
        let focusScript: String
        if tab.browserAppName == "Safari" {
            focusScript = """
            tell application "Safari"
                activate
                set index of window \(tab.windowIndex) to 1
                set current tab of window 1 to tab \(tab.tabIndex) of window \(tab.windowIndex)
            end tell
            """
        } else {
            focusScript = """
            tell application "\(tab.browserAppName)"
                activate
                set active tab index of window \(tab.windowIndex) to \(tab.tabIndex)
                set index of window \(tab.windowIndex) to 1
            end tell
            """
        }
        var errorDict: NSDictionary?
        NSAppleScript(source: focusScript)?.executeAndReturnError(&errorDict)
        if let errorDict {
            print("BrowserTabSource: no pude enfocar la pestaña -> \(errorDict)")
            return
        }

        usleep(200_000) // dar tiempo a que la ventana pase de verdad a primer plano

        let keystrokeScript = """
        tell application "System Events"
            keystroke " "
        end tell
        """
        NSAppleScript(source: keystrokeScript)?.executeAndReturnError(&errorDict)
        if let errorDict {
            print("BrowserTabSource: fallback de teclado falló (¿permiso de Accesibilidad en System Settings > Privacidad > Accesibilidad?) -> \(errorDict)")
        }
    }

    private static func isRunning(_ appName: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.localizedName == appName }
    }

    private static func fetchChromiumTabs(appName: String) -> [BrowserTab] {
        let script = """
        set output to ""
        tell application "\(appName)"
            set winIdx to 0
            repeat with w in windows
                set winIdx to winIdx + 1
                set activeIdx to active tab index of w
                set tabIdx to 0
                repeat with t in tabs of w
                    set tabIdx to tabIdx + 1
                    set isActive to "0"
                    if tabIdx is activeIdx then set isActive to "1"
                    set output to output & winIdx & "\t" & tabIdx & "\t" & isActive & "\t" & (title of t) & "\t" & (URL of t) & "\n"
                end repeat
            end repeat
        end tell
        return output
        """
        return runScript(script, appName: appName)
    }

    private static func fetchSafariTabs() -> [BrowserTab] {
        let script = """
        set output to ""
        tell application "Safari"
            set winIdx to 0
            repeat with w in windows
                set winIdx to winIdx + 1
                set activeTabRef to current tab of w
                set tabIdx to 0
                repeat with t in tabs of w
                    set tabIdx to tabIdx + 1
                    set isActive to "0"
                    if t is activeTabRef then set isActive to "1"
                    set output to output & winIdx & "\t" & tabIdx & "\t" & isActive & "\t" & (name of t) & "\t" & (URL of t) & "\n"
                end repeat
            end repeat
        end tell
        return output
        """
        return runScript(script, appName: "Safari")
    }

    private static func runScript(_ source: String, appName: String) -> [BrowserTab] {
        guard let script = NSAppleScript(source: source) else { return [] }
        var errorDict: NSDictionary?
        let result = script.executeAndReturnError(&errorDict)
        if let errorDict {
            print("BrowserTabSource: error AppleScript (\(appName)) -> \(errorDict)")
            return []
        }
        guard let text = result.stringValue else { return [] }

        var tabs: [BrowserTab] = []
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 4, omittingEmptySubsequences: false)
            guard parts.count == 5,
                  let winIdx = Int(parts[0]), let tabIdx = Int(parts[1]),
                  let url = URL(string: String(parts[4])),
                  url.scheme?.hasPrefix("http") == true else { continue }
            tabs.append(BrowserTab(
                browserAppName: appName,
                windowIndex: winIdx,
                tabIndex: tabIdx,
                title: String(parts[3]),
                url: url,
                isActive: parts[2] == "1" && winIdx == 1
            ))
        }
        return tabs
    }
}
