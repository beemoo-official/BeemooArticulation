import AVFoundation
import Foundation

/// Speaks lines with pre-recorded voice clips (e.g. generated with ElevenLabs), falling back to the
/// system voice for any line that has no clip yet.
///
/// Clips live on the backend under `<folder>/<slug>.mp3`, where the slug is the spoken text in
/// lowercase with everything except letters and digits turned into underscores:
///   "Help the monkey climb the tree! Say the words!" → help_the_monkey_climb_the_tree_say_the_words.mp3
///   "bus" → bus.mp3
/// Downloaded clips are cached on disk, so each one is fetched only once.
///
/// Word-by-word bubble reveal: clip downloads don't include word timings, so word callbacks are
/// spread across the clip in proportion to each word's length. Good enough for short lines.
final class VoiceClipNarrationTrack: NSObject, NarrationTrack, AVAudioPlayerDelegate {
    private let apiClient: APIClient
    private let folder: String
    private let fallback = SystemNarrationTrack()
    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?
    private var wordTimers: [DispatchWorkItem] = []
    private var token = 0

    init(apiClient: APIClient, folder: String = "voice/beemoo") {
        self.apiClient = apiClient
        self.folder = folder
        super.init()
    }

    static func slug(for text: String) -> String {
        let stripped = StrippedText(from: text).stripped.lowercased()
        var out = ""
        var lastWasUnderscore = false
        for ch in stripped {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasUnderscore = false
            } else if !lastWasUnderscore && !out.isEmpty {
                out.append("_")
                lastWasUnderscore = true
            }
        }
        while out.hasSuffix("_") { out.removeLast() }
        return out
    }

    func speak(_ text: String,
               onWord: @escaping (Range<String.Index>) -> Void,
               onFinish: @escaping () -> Void) {
        stop()
        token += 1
        let current = token
        let stripped = StrippedText(from: text).stripped
        let path = "\(folder)/\(Self.slug(for: text)).mp3"

        Task { @MainActor in
            let data = await self.loadClip(path)
            guard current == self.token else { return }   // a newer line started meanwhile
            guard let data, let player = try? AVAudioPlayer(data: data) else {
                self.fallback.speak(text, onWord: onWord, onFinish: onFinish)
                return
            }
            GameAudioSession.prepareForPlayback()
            player.delegate = self
            self.player = player
            self.onFinish = onFinish
            self.scheduleWords(in: stripped, duration: player.duration, onWord: onWord)
            player.play()
        }
    }

    func stop() {
        token += 1
        player?.stop()
        player = nil
        wordTimers.forEach { $0.cancel() }
        wordTimers.removeAll()
        fallback.stop()
        onFinish = nil
    }

    // MARK: - Word timing

    /// One callback per word (matching how the speech bubble counts words), spread over the clip.
    private func scheduleWords(in text: String, duration: TimeInterval, onWord: @escaping (Range<String.Index>) -> Void) {
        var ranges: [Range<String.Index>] = []
        var i = text.startIndex
        while i < text.endIndex {
            while i < text.endIndex, text[i] == " " { i = text.index(after: i) }
            guard i < text.endIndex else { break }
            var j = i
            while j < text.endIndex, text[j] != " " { j = text.index(after: j) }
            ranges.append(i..<j)
            i = j
        }
        guard !ranges.isEmpty else { return }
        let weights = ranges.map { Double(text.distance(from: $0.lowerBound, to: $0.upperBound)) + 2 }
        let total = weights.reduce(0, +)
        let leadIn = min(0.08, duration * 0.1)
        let speaking = max(duration * 0.9 - leadIn, 0.05)
        var t = leadIn
        for (k, range) in ranges.enumerated() {
            let item = DispatchWorkItem { onWord(range) }
            wordTimers.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: item)
            t += speaking * weights[k] / total
        }
    }

    // MARK: - Loading + cache

    private func loadClip(_ path: String) async -> Data? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("beemoo-voice", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let cached = cacheDir.appendingPathComponent(path.replacingOccurrences(of: "/", with: "_"))
        if let data = try? Data(contentsOf: cached) { return data }
        let url = apiClient.mediaURL(for: path)
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else { return nil }
        try? data.write(to: cached, options: .atomic)
        return data
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        MainActor.assumeIsolated {
            guard player === self.player else { return }
            let finish = self.onFinish
            self.onFinish = nil
            self.player = nil
            finish?()
        }
    }
}
