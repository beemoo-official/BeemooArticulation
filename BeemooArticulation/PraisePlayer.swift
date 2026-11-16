import Foundation

/// Plays a random BEEMOO encouragement clip (voice/beemoo/<slug>.mp3) after a correct word.
/// Never repeats the same phrase twice in a row.
final class PraisePlayer {
    static let phrases = [
        "You did it!", "Great job!", "Amazing!", "Way to go!", "Super star!",
        "Awesome work!", "Fantastic!", "Keep it up!", "High five!", "Woohoo!",
    ]

    private var voice: VoiceClipNarrationTrack?
    private var last: String?

    func configure(apiClient: APIClient) {
        voice = VoiceClipNarrationTrack(apiClient: apiClient)
    }

    func play() {
        let choices = Self.phrases.filter { $0 != last }
        guard let phrase = choices.randomElement() else { return }
        last = phrase
        voice?.speak(phrase, onWord: { _ in }, onFinish: {})
    }

    func stop() { voice?.stop() }
}
