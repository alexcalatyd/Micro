import SwiftUI

/// Guía de bienvenida que se muestra la primera vez que se abre Micro (y
/// bajo demanda desde el panel de la barra de menú). Explica en pocos
/// pasos cómo vivir con una app sin ventana principal ni icono en el Dock.
struct OnboardingView: View {
    @State var language: AppLanguage
    var onFinish: () -> Void

    @State private var page = 0
    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                icon(for: page)
                    .font(.system(size: 46))
                    .foregroundStyle(Color.accentColor)
                    .frame(height: 56)

                VStack(spacing: 10) {
                    Text(title(for: page))
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                    Text(body(for: page))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if page == 3 {
                    VStack(alignment: .leading, spacing: 6) {
                        shortcutRow(key: "← →", description: SettingsStrings.t(.shortcutSeek, language))
                        shortcutRow(key: "␣", description: SettingsStrings.t(.shortcutPlayPause, language))
                        shortcutRow(key: "⌘R", description: SettingsStrings.t(.shortcutReload, language))
                        shortcutRow(key: "⌘H", description: SettingsStrings.t(.shortcutHide, language))
                        shortcutRow(key: "⌘W", description: SettingsStrings.t(.shortcutClose, language))
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)
            .frame(height: 330, alignment: .top)

            Spacer(minLength: 16)

            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 18)

            HStack {
                Picker("", selection: $language) {
                    Text(SettingsStrings.t(.languageEnglish, language)).tag(AppLanguage.en)
                    Text(SettingsStrings.t(.languageSpanish, language)).tag(AppLanguage.es)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.mini)
                .frame(width: 100)

                if page > 0 {
                    Button(OnboardingStrings.t(.back, language)) {
                        withAnimation(.easeInOut(duration: 0.2)) { page -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(page == pageCount - 1 ? OnboardingStrings.t(.getStarted, language) : OnboardingStrings.t(.next, language)) {
                    if page == pageCount - 1 {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) { page += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .frame(width: 420)
    }

    private func icon(for page: Int) -> Image {
        switch page {
        case 0: return Image(systemName: "play.rectangle.fill")
        case 1: return Image(systemName: "rectangle.on.rectangle")
        case 2: return Image(systemName: "arrow.up.left.and.arrow.down.right")
        default: return Image(systemName: "keyboard")
        }
    }

    private func title(for page: Int) -> String {
        switch page {
        case 0: return OnboardingStrings.t(.step1Title, language)
        case 1: return OnboardingStrings.t(.step2Title, language)
        case 2: return OnboardingStrings.t(.step3Title, language)
        default: return OnboardingStrings.t(.step4Title, language)
        }
    }

    private func body(for page: Int) -> String {
        switch page {
        case 0: return OnboardingStrings.t(.step1Body, language)
        case 1: return OnboardingStrings.t(.step2Body, language)
        case 2: return OnboardingStrings.t(.step3Body, language)
        default: return OnboardingStrings.t(.step4Body, language)
        }
    }
}
