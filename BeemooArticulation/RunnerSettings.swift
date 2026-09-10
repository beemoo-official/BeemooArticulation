import Foundation

// MARK: - Runner settings (read at screen-entry time)

@Observable
final class RunnerSettings {
    /// What happens on a wrong answer.
    var wrongAnswerResponse: WrongAnswerResponse = .retrySameScreen

    /// Whether the activity auto-advances on correct or waits for an adult tap.
    var advanceGating: AdvanceGating = .adultTaps

    /// Whether narration is enabled. Off still shows text and logs trials.
    var narrationEnabled: Bool = true

    enum WrongAnswerResponse: Sendable {
        case retrySameScreen
        case advanceAnyway
        case reTeachThenRetry
    }

    enum AdvanceGating: Sendable {
        case autoAdvance
        case adultTaps
    }
}
