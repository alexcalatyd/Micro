import SwiftUI

struct SettingsPanelView: View {
    @State var level: WindowLevelPreference
    @State var language: AppLanguage
    var onSelectLevel: (WindowLevelPreference) -> Void
    var onSelectSize: (NSSize) -> Void
    var onSelectLanguage: (AppLanguage) -> Void
    var onReload: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SettingsStrings.t(.settingsTitle, language)).font(.headline)

            panelSection(SettingsStrings.t(.windowSection, language)) {
                windowLevelPicker(level: $level, language: language, onChange: onSelectLevel)
            }

            panelSection(SettingsStrings.t(.sizeSection, language)) {
                sizePresetButtons(language: language, onSelect: onSelectSize)
            }

            keyboardShortcutsSection(language: language)

            languagePicker(language: $language, onChange: onSelectLanguage)

            Divider()

            HStack {
                Button(action: onReload) {
                    Label(SettingsStrings.t(.reload, language), systemImage: "arrow.clockwise")
                }
                Spacer()
                Button(role: .destructive, action: onClose) {
                    Label(SettingsStrings.t(.close, language), systemImage: "xmark.circle")
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .fixedSize(horizontal: false, vertical: true)
    }
}
