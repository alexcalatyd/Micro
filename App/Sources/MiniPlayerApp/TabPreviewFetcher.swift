import Foundation

/// Consigue una imagen de preview para una pestaña. No existe ninguna API
/// pública para capturar el píxel real de una pestaña en segundo plano (el
/// navegador solo renderiza la pestaña activa de cada ventana), así que
/// usamos la mejor aproximación disponible: el thumbnail oficial de YouTube
/// cuando aplica, o la imagen og:image de la página en los demás casos.
enum TabPreviewFetcher {
    static func thumbnail(for url: URL) async -> URL? {
        if let yt = youtubeThumbnail(for: url) { return yt }
        return await fetchOGImage(for: url)
    }

    private static func youtubeThumbnail(for url: URL) -> URL? {
        guard let parsed = YouTubeURLHelper.parse(url) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(parsed.videoID)/hqdefault.jpg")
    }

    private static func fetchOGImage(for url: URL) async -> URL? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 4
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            return nil
        }

        let pattern = #"<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }
        return URL(string: String(html[range]))
    }
}
