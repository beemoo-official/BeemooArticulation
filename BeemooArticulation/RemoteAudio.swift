import AVFoundation
import Foundation

/// Fetches audio files from the Django backend, caches to disk, and plays them.
@Observable
final class RemoteAudioPlayer {
    private var player: AVAudioPlayer?
    private let cacheDir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("beemoo-audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Play an audio file by path (e.g. "sfx/popEffect.mp3"), fetching from the backend if not cached.
    func play(_ path: String, from apiClient: APIClient) {
        // Flatten the path for local caching (sfx/popEffect.mp3 → sfx_popEffect.mp3)
        let cacheKey = path.replacingOccurrences(of: "/", with: "_")
        let localURL = cacheDir.appendingPathComponent(cacheKey)

        if FileManager.default.fileExists(atPath: localURL.path) {
            playLocal(localURL)
            return
        }

        // Download in background, then play
        let remoteURL = apiClient.mediaURL(for: path)
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
                try data.write(to: localURL, options: .atomic)
                await MainActor.run { playLocal(localURL) }
            } catch {}
        }
    }

    private func playLocal(_ url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
