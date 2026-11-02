import Foundation

/// Extrae el ID de vídeo + tiempo de inicio de una URL de YouTube
/// (watch?v=... o youtu.be/...), y genera una página local que usa la API
/// oficial de YouTube (IFrame Player API) para poder controlar el vídeo
/// de verdad desde Swift (seek, play/pause) — un <iframe> a pelo no se
/// puede controlar porque es contenido de otro origen.
enum YouTubeURLHelper {
    struct Parsed {
        let videoID: String
        let startSeconds: Int
    }

    static func parse(_ url: URL) -> Parsed? {
        guard let host = url.host else { return nil }

        var videoID: String?
        var startSeconds: Int?

        if host.contains("youtube.com"), url.path == "/watch" {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            videoID = items.first(where: { $0.name == "v" })?.value
            startSeconds = items.first(where: { $0.name == "t" })?.value.flatMap(parseSeconds)
        } else if host.contains("youtu.be") {
            videoID = url.pathComponents.last
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            startSeconds = items.first(where: { $0.name == "t" })?.value.flatMap(parseSeconds)
        }

        guard let id = videoID, !id.isEmpty else { return nil }
        return Parsed(videoID: id, startSeconds: startSeconds ?? 0)
    }

    /// Página local que carga el reproductor vía la IFrame Player API.
    /// Expone window.__miniplayerSeek(delta) y window.__miniplayerToggle()
    /// para que Swift pueda controlar el vídeo con las flechas/espacio.
    static func wrapperHTML(parsed: Parsed) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          html, body { margin: 0; padding: 0; background: #000; overflow: hidden; }
          #ytplayer { position: absolute; inset: 0; width: 100%; height: 100%; }
          #ytplayer iframe { width: 100% !important; height: 100% !important; }
        </style>
        </head>
        <body>
          <div id="ytplayer"></div>
          <script src="https://www.youtube.com/iframe_api"></script>
          <script>
            var player;
            function fitPlayer() {
              if (player && player.setSize) {
                player.setSize(window.innerWidth, window.innerHeight);
              }
            }
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('ytplayer', {
                width: window.innerWidth,
                height: window.innerHeight,
                videoId: '\(parsed.videoID)',
                playerVars: {
                  autoplay: 1,
                  playsinline: 1,
                  start: \(parsed.startSeconds),
                  origin: 'https://example.com',
                  cc_load_policy: 0
                },
                events: {
                  onReady: function(e) {
                    // Si YouTube recuerda una preferencia de subtítulos
                    // (cookie de cuenta/navegador), cc_load_policy no basta
                    // por sí solo — hay que descargar el módulo a mano.
                    if (e.target.unloadModule) { e.target.unloadModule('captions'); }
                    e.target.playVideo();
                    fitPlayer();
                  }
                }
              });
            }
            window.__miniplayerSeek = function(delta) {
              if (!player || !player.getCurrentTime) return;
              player.seekTo(Math.max(0, player.getCurrentTime() + delta), true);
            };
            window.__miniplayerToggle = function() {
              if (!player || !player.getPlayerState) return;
              player.getPlayerState() === 1 ? player.pauseVideo() : player.playVideo();
            };
            window.__miniplayerCurrentTimeAndPause = function() {
              if (!player || !player.getCurrentTime) return 0;
              var t = player.getCurrentTime();
              player.pauseVideo && player.pauseVideo();
              return t;
            };
            window.addEventListener('resize', fitPlayer);
          </script>
        </body>
        </html>
        """
    }

    /// Acepta "90", "90s", "1m30s"
    private static func parseSeconds(_ raw: String) -> Int? {
        if let plain = Int(raw) { return plain }
        var total = 0
        var current = ""
        for char in raw {
            if char.isNumber {
                current.append(char)
            } else {
                let value = Int(current) ?? 0
                switch char {
                case "h": total += value * 3600
                case "m": total += value * 60
                case "s": total += value
                default: break
                }
                current = ""
            }
        }
        return total == 0 ? nil : total
    }
}
