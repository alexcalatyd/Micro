import Foundation

/// Textos de los paneles de ajustes (solo la interfaz de ajustes), en los
/// dos idiomas soportados. El resto de la app (código, comentarios) sigue
/// en español tal cual estaba.
enum SettingsStrings {
    enum Key {
        case appName
        case settingsTitle
        case openBrowserTab
        case activeWindowSection
        case windowSection
        case alwaysOnTop
        case normalWindow
        case sizeSection
        case small
        case medium
        case large
        case shortcutsSection
        case shortcutSeek
        case shortcutPlayPause
        case shortcutReload
        case shortcutClose
        case shortcutHide
        case reload
        case hide
        case show
        case close
        case quit
        case languageSection
        case languageEnglish
        case languageSpanish
        case noTabs
    }

    private static let en: [Key: String] = [
        .appName: "Micro",
        .settingsTitle: "Settings",
        .openBrowserTab: "Open browser tab",
        .activeWindowSection: "ACTIVE WINDOW",
        .windowSection: "WINDOW",
        .alwaysOnTop: "Always on top",
        .normalWindow: "Normal window",
        .sizeSection: "SIZE",
        .small: "Small",
        .medium: "Medium",
        .large: "Large",
        .shortcutsSection: "KEYBOARD SHORTCUTS",
        .shortcutSeek: "Rewind / forward 10s",
        .shortcutPlayPause: "Play / pause",
        .shortcutReload: "Reload",
        .shortcutClose: "Close",
        .shortcutHide: "Hide window",
        .reload: "Reload",
        .hide: "Hide",
        .show: "Show",
        .close: "Close",
        .quit: "Quit Micro",
        .languageSection: "LANGUAGE",
        .languageEnglish: "English",
        .languageSpanish: "Español",
        .noTabs: "No open tabs (browser closed, or missing Automation permission?)"
    ]

    private static let es: [Key: String] = [
        .appName: "Micro",
        .settingsTitle: "Ajustes",
        .openBrowserTab: "Abrir pestaña del navegador",
        .activeWindowSection: "VENTANA ACTIVA",
        .windowSection: "VENTANA",
        .alwaysOnTop: "Siempre encima",
        .normalWindow: "Ventana normal",
        .sizeSection: "TAMAÑO",
        .small: "Pequeña",
        .medium: "Mediana",
        .large: "Grande",
        .shortcutsSection: "ATAJOS DE TECLADO",
        .shortcutSeek: "Retroceder / avanzar 10s",
        .shortcutPlayPause: "Reproducir / pausar",
        .shortcutReload: "Recargar",
        .shortcutClose: "Cerrar",
        .shortcutHide: "Ocultar ventana",
        .reload: "Recargar",
        .hide: "Ocultar",
        .show: "Mostrar",
        .close: "Cerrar",
        .quit: "Salir de Micro",
        .languageSection: "IDIOMA",
        .languageEnglish: "English",
        .languageSpanish: "Español",
        .noTabs: "Sin pestañas abiertas (¿navegador cerrado o falta permiso de Automatización?)"
    ]

    static func t(_ key: Key, _ language: AppLanguage) -> String {
        let table = language == .es ? es : en
        return table[key] ?? ""
    }
}
