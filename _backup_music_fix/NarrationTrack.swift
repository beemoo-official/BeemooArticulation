import AVFoundation
import Foundation

// MARK: - Protocol

protocol NarrationTrack: AnyObject {
    /// Speak the text. `onWord` fires for each word boundary with the range in the
    /// **stripped** string (no asterisks). `onFinish` fires when done.
    func speak(_ text: String,
               onWord: @escaping (Range<String.Index>) -> Void,
               onFinish: @escaping () -> Void)
    func stop()
}

// MARK: - Marker stripping + range map

/// Strips `*markers*` from text for TTS, keeping a map from stripped ranges
/// back to the original so the concept word can be identified.
struct StrippedText {
    let stripped: String
    /// Ranges in `stripped` that correspond to marked (concept) words in the original.
    let markedRanges: [Range<String.Index>]

    init(from markerText: String) {
        var result = ""
        var marked: [Range<String.Index>] = []
        var remaining = markerText[...]

        while let starStart = remaining.firstIndex(of: "*") {
            result += remaining[remaining.startIndex..<starStart]

            let afterStar = remaining.index(after: starStart)
            guard afterStar < remaining.endIndex,
                  let starEnd = remaining[afterStar...].firstIndex(of: "*") else {
                result += remaining[starStart...]
                remaining = remaining[remaining.endIndex...]
                break
            }

            let word = String(remaining[afterStar..<starEnd])
            let rangeStart = result.endIndex
            result += word
            let rangeEnd = result.endIndex
            marked.append(rangeStart..<rangeEnd)

            remaining = remaining[remaining.index(after: starEnd)...]
        }

        if !remaining.isEmpty {
            result += remaining
        }

        self.stripped = result
        self.markedRanges = marked
    }

    /// Returns true if the given range in the stripped string overlaps a marked concept word.
    func isMarked(_ range: Range<String.Index>) -> Bool {
        markedRanges.contains { $0.overlaps(range) }
    }
}

// MARK: - System implementation (AVSpeechSynthesizer)

final class SystemNarrationTrack: NSObject, NarrationTrack, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var onWord: ((Range<String.Index>) -> Void)?
    private var onFinish: (() -> Void)?
    private var currentText: String = ""

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String,
               onWord: @escaping (Range<String.Index>) -> Void,
               onFinish: @escaping () -> Void) {
        stop()

        let stripped = StrippedText(from: text)
        currentText = stripped.stripped
        self.onWord = onWord
        self.onFinish = onFinish

        let utterance = AVSpeechUtterance(string: stripped.stripped)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.1
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        onWord = nil
        onFinish = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        MainActor.assumeIsolated {
            guard let range = Range(characterRange, in: currentText) else { return }
            onWord?(range)
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        MainActor.assumeIsolated {
            onFinish?()
        }
    }
}
