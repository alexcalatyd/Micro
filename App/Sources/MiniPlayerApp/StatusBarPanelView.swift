import SwiftUI

struct StatusBarPanelView: View {
    @State var level: WindowLevelPreference
    @State var language: AppLanguage
    var onOpenTabPicker: () -> Void
    var onSelectLevel: (WindowLevelPreference) -> Void
    var onSelectSize: (NSSize) -> Void
    var onSelectLanguage: (AppLanguage) -> Void
    var onReloadActive: () -> Void
    /// true si ahora mismo hay mini reproductores ocultos (⌘H): el botón
    /// pasa a ser "Mostrar" para poder recuperarlos.
    var hasHiddenPlayers: Bool
    var onToggleHidden: () -> Void
    var onCloseActive: () -> Void
    var onShowGuide: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SettingsStrings.t(.appName, language)).font(.headline)

            Button(action: onOpenTabPicker) {
                Label(SettingsStrings.t(.openBrowserTab, language), systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            panelSection(SettingsStrings.t(.activeWindowSection, language)) {
                HStack {
                    Button(action: onReloadActive) {
                        Label(SettingsStrings.t(.reload, language), systemImage: "arrow.clockwise")
                    }
                    Button(action: onToggleHidden) {
                        Label(
                            SettingsStrings.t(hasHiddenPlayers ? .show : .hide, language),
                            systemImage: hasHiddenPlayers ? "eye" : "eye.slash"
                        )
                    }
                    Spacer()
                    Button(role: .destructive, action: onCloseActive) {
                        Label(SettingsStrings.t(.close, language), systemImage: "xmark.circle")
                    }
                }
            }

            panelSection(SettingsStrings.t(.windowSection, language)) {
                windowLevelPicker(level: $level, language: language, onChange: onSelectLevel)
            }

            panelSection(SettingsStrings.t(.sizeSection, language)) {
                sizePresetButtons(language: language, onSelect: onSelectSize)
            }

            keyboardShortcutsSection(language: language)

            languagePicker(language: $language, onChange: onSelectLanguage)

            Button(action: onShowGuide) {
                Label(OnboardingStrings.t(.showGuideAgain, language), systemImage: "questionmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .font(.caption)

            Divider()

            Button(role: .destructive, action: onQuit) {
                Label(SettingsStrings.t(.quit, language), systemImage: "power")
            }
        }
        .padding(16)
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
    }
}
