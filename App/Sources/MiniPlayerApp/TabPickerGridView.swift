import SwiftUI

struct TabPickerGridView: View {
    let tabs: [BrowserTab]
    var onSelect: (BrowserTab) -> Void

    var body: some View {
        if tabs.isEmpty {
            Text(SettingsStrings.t(.noTabs, PlayerSettings.shared.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(20)
                .frame(width: 320)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 12)], spacing: 12) {
                    ForEach(tabs) { tab in
                        TabPreviewCard(tab: tab, onSelect: onSelect)
                    }
                }
                .padding(12)
            }
            .frame(width: 420, height: 340)
        }
    }
}

private struct TabPreviewCard: View {
    let tab: BrowserTab
    var onSelect: (BrowserTab) -> Void
    @State private var previewURL: URL?

    var body: some View {
        Button(action: { onSelect(tab) }) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.12))
                    if let previewURL {
                        AsyncImage(url: previewURL) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(16.0 / 9.0, contentMode: .fill)
                            } else {
                                Image(systemName: "globe").foregroundStyle(.secondary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "globe").foregroundStyle(.secondary)
                    }
                }
                .frame(height: 84)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(tab.isActive ? Color.accentColor : .clear, lineWidth: 3)
                )

                Text(tab.title)
                    .font(.caption)
                    .lineLimit(1)
                Text(tab.url.host?.replacingOccurrences(of: "www.", with: "") ?? "")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .task {
            previewURL = await TabPreviewFetcher.thumbnail(for: tab.url)
        }
    }
}
