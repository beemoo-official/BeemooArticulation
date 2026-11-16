import AVFoundation
import Speech

/// Listens for one target word using speech recognition.
///
/// Lifecycle: `listen(for:onMatch:)` → hears the word → stops itself → calls `onMatch` once.
/// It keeps listening (opening a fresh recognition window every few seconds) until it hears
/// the word or `stop()` is called. Every call to `listen` or `stop` starts a new session, and
/// callbacks from older sessions or windows are ignored, so a late result can never count
/// for the wrong word.
///
/// Works on devices and on the simulator (which uses the Mac's microphone). If speech or microphone
/// permission is denied, or recognition keeps failing, `mode` becomes `.manual`: nothing listens,
/// and the adult taps "They said it" to confirm the word instead.
@Observable
final class WordRecognizer {
    enum Mode { case speech, manual }

    private(set) var isListening = false
    private(set) var mode: Mode = .speech
    /// What the recognizer has heard so far for the current word (shown under the mic button).
    private(set) var lastHeard = ""
    /// Live microphone input level while listening, 0…1, for a "we can hear you" meter.
    private(set) var level: Float = 0

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var engine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var session = 0
    private var window = 0
    private var quickFailures = 0
    private var target = ""
    private var onMatch: (() -> Void)?

    init() {}

    /// Start listening for `word`. `onMatch` runs once, on the main thread, when the word is heard.
    func listen(for word: String, onMatch: @escaping () -> Void) {
        stop()
        target = word.lowercased()
        lastHeard = ""
        self.onMatch = onMatch
        quickFailures = 0
        guard mode == .speech else { return }
        let token = session
        Self.requestPermissions { [weak self] granted in
            guard let self, token == self.session else { return }
            guard granted, self.recognizer?.isAvailable == true else {
                self.mode = .manual
                return
            }
            self.openWindow(session: token)
        }
    }

    /// Stop listening and forget the current word. Safe to call at any time.
    func stop() {
        session += 1
        closeWindow()
        onMatch = nil
    }

    // MARK: - Recognition windows

    private func openWindow(session token: Int) {
        guard token == session, let recognizer else { return }
        closeWindow()
        window += 1
        let windowID = window
        let openedAt = Date()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = [target]
        #if !targetEnvironment(simulator)
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
        #endif

        let engine = AVAudioEngine()
        do {
            try GameAudioSession.activate()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.channelCount > 0, format.sampleRate > 0 else { mode = .manual; return }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable [weak self] buffer, _ in
                request.append(buffer)
                let level = Self.normalizedLevel(of: buffer)
                Task { @MainActor in
                    guard let self, windowID == self.window, self.isListening else { return }
                    // Rise fast, fall slowly, so the bars read as speech rather than flicker
                    self.level = level > self.level ? level : self.level * 0.8 + level * 0.2
                }
            }
            engine.prepare()
            try engine.start()
        } catch {
            mode = .manual
            return
        }
        self.engine = engine
        self.request = request
        isListening = true

        task = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
            let heard = result?.bestTranscription.formattedString ?? ""
            let ended = error != nil || (result?.isFinal ?? false)
            Task { @MainActor in
                self?.handle(heard: heard, ended: ended, session: token, window: windowID, openedAt: openedAt)
            }
        }

        // Close each window after 8 s; its final result opens the next one.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            guard let self, token == self.session, windowID == self.window else { return }
            self.request?.endAudio()
        }
    }

    private func handle(heard: String, ended: Bool, session token: Int, window windowID: Int, openedAt: Date) {
        guard token == session, windowID == window else { return }   // stale callback
        if !heard.isEmpty { lastHeard = heard }
        if Self.transcript(heard, contains: target) {
            let callback = onMatch
            stop()
            callback?()
            return
        }
        guard ended else { return }
        // The window ended without the word: open a fresh one and keep listening.
        // If windows keep failing instantly, recognition isn't working here: fall back to manual.
        quickFailures = Date().timeIntervalSince(openedAt) < 1 ? quickFailures + 1 : 0
        closeWindow()
        if quickFailures >= 3 { mode = .manual; return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.openWindow(session: token)
        }
    }

    private func closeWindow() {
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        engine = nil
        isListening = false
        level = 0
    }

    // MARK: - Helpers

    /// Whole-word match, so "bus" doesn't match "business"; also accepts a plural ("buses").
    static func transcript(_ heard: String, contains word: String) -> Bool {
        let words = heard.lowercased().split { !$0.isLetter && $0 != "'" }.map(String.init)
        return words.contains(word) || words.contains(word + "s") || words.contains(word + "es")
    }

    /// RMS of the buffer mapped from roughly -50…-10 dBFS onto 0…1.
    nonisolated private static func normalizedLevel(of buffer: AVAudioPCMBuffer) -> Float {
        guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let n = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<n { sum += samples[i] * samples[i] }
        let db = 20 * log10(max(sqrt(sum / Float(n)), 1e-6))
        return min(max((db + 50) / 40, 0), 1)
    }

    /// Permission callbacks arrive on background threads; this hops back to the main actor.
    nonisolated private static func requestPermissions(_ done: @escaping @Sendable @MainActor (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { @Sendable status in
            guard status == .authorized else {
                Task { @MainActor in done(false) }
                return
            }
            AVAudioApplication.requestRecordPermission { @Sendable granted in
                Task { @MainActor in done(granted) }
            }
        }
    }
}
