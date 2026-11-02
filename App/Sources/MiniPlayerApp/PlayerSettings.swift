import AppKit

enum WindowLevelPreference: String {
    case floating   // siempre encima de todo
    case normal     // se comporta como una ventana normal (se puede tapar)

    var nsWindowLevel: NSWindow.Level {
        switch self {
        case .floating: return .floating
        case .normal: return .normal
        }
    }

    var menuTitle: String {
        switch self {
        case .floating: return "Siempre encima"
        case .normal: return "Ventana normal"
        }
    }
}

enum AppLanguage: String {
    case en
    case es
}

struct SizePreset {
    let name: String
    let size: NSSize
}

/// Preferencias globales del mini reproductor, persistidas en UserDefaults.
/// Se aplican a toda ventana nueva hasta que el usuario las cambie.
final class PlayerSettings {
    static let shared = PlayerSettings()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let level = "miniplayer.windowLevel"
        static let frame = "miniplayer.lastFrame"
        static let videoPositions = "miniplayer.videoPositions"
        static let language = "miniplayer.language"
        static let hasCompletedOnboarding = "miniplayer.hasCompletedOnboarding"
    }

    // Idioma de los paneles de ajustes. Por defecto inglés.
    var language: AppLanguage {
        get { AppLanguage(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .en }
        set { defaults.set(newValue.rawValue, forKey: Keys.language) }
    }

    // Si ya se vio la guía de bienvenida (se muestra sola la primera vez).
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // Proporción 16:9: así el vídeo (la mayoría de contenido lo es) llena la
    // ventana entera, sin bandas negras arriba/abajo ni a los lados.
    static let sizePresets: [SizePreset] = [
        SizePreset(name: "Pequeña", size: NSSize(width: 320, height: 180)),
        SizePreset(name: "Mediana", size: NSSize(width: 480, height: 270)),
        SizePreset(name: "Grande", size: NSSize(width: 720, height: 405))
    ]

    var windowLevel: WindowLevelPreference {
        get { WindowLevelPreference(rawValue: defaults.string(forKey: Keys.level) ?? "") ?? .floating }
        set { defaults.set(newValue.rawValue, forKey: Keys.level) }
    }

    var lastFrame: NSRect? {
        get {
            guard let raw = defaults.string(forKey: Keys.frame) else { return nil }
            return NSRectFromString(raw)
        }
        set {
            guard let newValue else { return }
            defaults.set(NSStringFromRect(newValue), forKey: Keys.frame)
        }
    }

    // Recuerda por dónde quedó cada vídeo de YouTube (por ID), para
    // retomarlo si se vuelve a abrir el mismo vídeo más adelante.
    func lastPosition(forVideoID videoID: String) -> Double? {
        let positions = defaults.dictionary(forKey: Keys.videoPositions) as? [String: Double]
        return positions?[videoID]
    }

    func setLastPosition(_ seconds: Double, forVideoID videoID: String) {
        var positions = defaults.dictionary(forKey: Keys.videoPositions) as? [String: Double] ?? [:]
        positions[videoID] = seconds
        defaults.set(positions, forKey: Keys.videoPositions)
    }
}
