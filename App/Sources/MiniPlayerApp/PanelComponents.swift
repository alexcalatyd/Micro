import SwiftUI

/// Piezas visuales compartidas entre el panel de ajustes de cada ventana y
/// el panel de la barra de menú, para que ambos se vean iguales.
///
/// El idioma se pasa siempre como parámetro (no se lee de PlayerSettings
/// aquí dentro) para que SwiftUI recalcule los textos al instante cuando
/// cambia el @State de idioma de la vista, sin esperar a reabrir el panel.
@ViewBuilder
func panelSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.caption2)
            .foregroundStyle(.secondary)
        content()
    }
}

func shortcutRow(key: String, description: String) -> some View {
    HStack(spacing: 8) {
        Text(description).font(.caption)
        Spacer()
        Text(key)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(4)
    }
}

func windowLevelPicker(level: Binding<WindowLevelPreference>, language: AppLanguage, onChange: @escaping (WindowLevelPreference) -> Void) -> some View {
    Picker("", selection: level) {
        Text(SettingsStrings.t(.alwaysOnTop, language)).tag(WindowLevelPreference.floating)
        Text(SettingsStrings.t(.normalWindow, language)).tag(WindowLevelPreference.normal)
    }
    .pickerStyle(.segmented)
    .labelsHidden()
    .onChange(of: level.wrappedValue) { onChange($0) }
}

func sizePresetButtons(language: AppLanguage, onSelect: @escaping (NSSize) -> Void) -> some View {
    let labels = [SettingsStrings.t(.small, language), SettingsStrings.t(.medium, language), SettingsStrings.t(.large, language)]
    return HStack(spacing: 8) {
        ForEach(PlayerSettings.sizePresets.indices, id: \.self) { index in
            Button(labels[index]) { onSelect(PlayerSettings.sizePresets[index].size) }
                .buttonStyle(.bordered)
        }
    }
}

func keyboardShortcutsSection(language: AppLanguage) -> some View {
    panelSection(SettingsStrings.t(.shortcutsSection, language)) {
        VStack(alignment: .leading, spacing: 6) {
            shortcutRow(key: "← →", description: SettingsStrings.t(.shortcutSeek, language))
            shortcutRow(key: "␣", description: SettingsStrings.t(.shortcutPlayPause, language))
            shortcutRow(key: "⌘R", description: SettingsStrings.t(.shortcutReload, language))
            shortcutRow(key: "⌘W", description: SettingsStrings.t(.shortcutClose, language))
        }
    }
}

func languagePicker(language: Binding<AppLanguage>, onChange: @escaping (AppLanguage) -> Void) -> some View {
    panelSection(SettingsStrings.t(.languageSection, language.wrappedValue)) {
        Picker("", selection: language) {
            Text(SettingsStrings.t(.languageEnglish, language.wrappedValue)).tag(AppLanguage.en)
            Text(SettingsStrings.t(.languageSpanish, language.wrappedValue)).tag(AppLanguage.es)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .onChange(of: language.wrappedValue) { onChange($0) }
    }
}
