import Foundation

/// Textos de la guía de bienvenida (onboarding), en los dos idiomas
/// soportados. Mismo patrón que SettingsStrings.swift.
enum OnboardingStrings {
    enum Key {
        case step1Title, step1Body
        case step2Title, step2Body
        case step3Title, step3Body
        case step4Title, step4Body
        case back, next, getStarted
        case showGuideAgain
    }

    private static let en: [Key: String] = [
        .step1Title: "Welcome to Micro",
        .step1Body: "Micro plays YouTube, Netflix and other videos in a small floating window, always on top of everything else. It lives in the menu bar — there's no Dock icon or app window to manage.",
        .step2Title: "Open a video",
        .step2Body: "Click the Micro icon in the menu bar, then \"Open browser tab\". Pick any open tab from the grid and it opens in the mini player — the original tab pauses itself automatically.",
        .step3Title: "Move, resize, stay on top",
        .step3Body: "Drag the top edge of the window to move it. Drag any corner to resize it — it always keeps a clean 16:9 shape. Use the ⚙️ button, or the menu bar icon, to toggle \"Always on top\" and pick a preset size.",
        .step4Title: "Keyboard shortcuts",
        .step4Body: "These work directly on the video, no need to click first. ⌘H hides the player without stopping it — bring it back from the menu bar.",
        .back: "Back",
        .next: "Next",
        .getStarted: "Get started",
        .showGuideAgain: "Show guide again"
    ]

    private static let es: [Key: String] = [
        .step1Title: "Bienvenido a Micro",
        .step1Body: "Micro reproduce vídeos de YouTube, Netflix y otros sitios en una ventanita flotante, siempre por encima de todo. Vive en la barra de menú — no tiene icono en el Dock ni ventana principal que gestionar.",
        .step2Title: "Abrir un vídeo",
        .step2Body: "Pulsa el icono de Micro en la barra de menú y luego \"Abrir pestaña del navegador\". Elige cualquier pestaña abierta de la rejilla y se abrirá en el mini reproductor — la pestaña original se pausa sola.",
        .step3Title: "Mover, redimensionar, encima de todo",
        .step3Body: "Arrastra desde el borde superior de la ventana para moverla. Arrastra cualquiera de las cuatro esquinas para redimensionarla — siempre mantiene la proporción 16:9. Usa el botón ⚙️, o el icono de la barra de menú, para activar \"Siempre encima\" y elegir un tamaño predefinido.",
        .step4Title: "Atajos de teclado",
        .step4Body: "Funcionan directamente sobre el vídeo, sin hacer clic antes. ⌘H oculta el reproductor sin pararlo — vuelve desde la barra de menú.",
        .back: "Atrás",
        .next: "Siguiente",
        .getStarted: "Empezar",
        .showGuideAgain: "Ver guía de nuevo"
    ]

    static func t(_ key: Key, _ language: AppLanguage) -> String {
        let table = language == .es ? es : en
        return table[key] ?? ""
    }
}
