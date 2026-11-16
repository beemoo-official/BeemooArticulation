import AVFoundation
import Foundation

/// Loops a music track from the backend (e.g. "music/silly_walks.m4a") for the length of a game.
/// The track is downloaded once and cached on disk.
/// `duck(true)` drops the volume (used while the mic is listening, so speech recognition
/// hears the child rather than the music); `duck(false)` brings it back up.
final class BackgroundMusicPlayer {
    private var player: AVAudioPlayer?
    private var wantsToPlay = false
    private let normalVolume: Float
    private let duckedVolume: Float

    init(normalVolume: Float = 0.35, duckedVolume: Float = 0.08) {
        self.normalVolume = normalVolume
        self.duckedVolume = duckedVolume
    }

    func start(_ path: String, apiClient: APIClient) {
        wantsToPlay = true
        Task { @MainActor in
            guard let data = await Self.load(path, apiClient: apiClient),
                  self.wantsToPlay,
                  let player = try? AVAudioPlayer(data: data) else { return }
            player.numberOfLoops = -1          // loop forever
            player.volume = 0
            player.prepareToPlay()
            player.play()
            player.setVolume(self.normalVolume, fadeDuration: 1.0)
            self.player = player
        }
    }

    func duck(_ ducked: Bool) {
        player?.setVolume(ducked ? duckedVolume : normalVolume, fadeDuration: 0.4)
    }

    func stop() {
        wantsToPlay = false
        guard let player else { return }
        player.setVolume(0, fadeDuration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { player.stop() }
        self.player = nil
    }

    private static func load(_ path: String, apiClient: APIClient) async -> Data? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("beemoo-music", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let cached = cacheDir.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_"))
        if let data = try? Data(contentsOf: cached) { return data }
        guard let (data, response) = try? await URLSession.shared.data(from: apiClient.mediaURL(for: path)),
              let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else { return nil }
        try? data.write(to: cached, options: .atomic)
        return data
    }
}
