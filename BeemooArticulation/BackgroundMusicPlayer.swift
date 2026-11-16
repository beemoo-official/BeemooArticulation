import AVFoundation
import Foundation

/// One audio-session setup shared by music, voice and the microphone during games.
/// Switching the session's category back and forth interrupts any music that is playing,
/// so the mic sets play+record once and narration leaves it alone after that.
enum GameAudioSession {
    /// Play + record, through the loudspeaker. Applied only if it isn't already the active setup.
    static func activate() throws {
        let s = AVAudioSession.sharedInstance()
        if s.category != .playAndRecord || s.mode != .default {
            try s.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        }
        try s.setActive(true)
    }

    /// For narration/music: keep play+record if the mic already set it, otherwise plain playback.
    static func prepareForPlayback() {
        let s = AVAudioSession.sharedInstance()
        if s.category != .playAndRecord {
            try? s.setCategory(.playback, mode: .spokenAudio)
        }
        try? s.setActive(true)
    }
}

/// Loops a music track from the backend (e.g. "music/silly_walks.m4a") for the length of a game.
/// The track is downloaded once and cached on disk. If something interrupts it (a call, Siri,
/// an audio route change), it picks up again.
final class BackgroundMusicPlayer {
    private var player: AVAudioPlayer?
    private var wantsToPlay = false
    private let volume: Float
    private var observers: [NSObjectProtocol] = []

    init(volume: Float = 0.35) {
        self.volume = volume
    }

    func start(_ path: String, apiClient: APIClient) {
        wantsToPlay = true
        observeInterruptions()
        Task { @MainActor in
            guard let data = await Self.load(path, apiClient: apiClient),
                  self.wantsToPlay,
                  let player = try? AVAudioPlayer(data: data) else { return }
            // Start in play+record so the mic opening later doesn't switch modes mid-song.
            try? GameAudioSession.activate()
            player.numberOfLoops = -1          // loop forever
            player.volume = 0
            player.prepareToPlay()
            player.play()
            player.setVolume(self.volume, fadeDuration: 1.0)
            self.player = player
        }
    }

    /// Restarts the loop if it was stopped by an interruption.
    func resumeIfNeeded() {
        guard wantsToPlay, let player, !player.isPlaying else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
    }

    func stop() {
        wantsToPlay = false
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        guard let player else { return }
        player.setVolume(0, fadeDuration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { player.stop() }
        self.player = nil
    }

    private func observeInterruptions() {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        for name in [AVAudioSession.interruptionNotification, AVAudioSession.routeChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    // Give the session a moment to settle, then carry on.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self?.resumeIfNeeded() }
                }
            })
        }
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
