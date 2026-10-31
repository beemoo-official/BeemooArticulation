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

    /// How the child's production is scored.
    var scoringMode: ScoringMode = .adultScored

    /// Number of trials before level completion check.
    var trialThreshold: Int = 10

    /// Accuracy percentage required to advance (0.0–1.0).
    var accuracyThreshold: Double = 0.80

    enum WrongAnswerResponse: Sendable, Hashable {
        case retrySameScreen
        case advanceAnyway
        case reTeachThenRetry
    }

    enum AdvanceGating: Sendable, Hashable {
        case autoAdvance
        case adultTaps
    }

    enum ScoringMode: Sendable, Hashable {
        case adultScored      // adult taps Correct / Try Again / Skip
        case autoReceptive    // existing tap-to-choose mode
    }
}
