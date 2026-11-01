import Foundation

/// Tracks /s/ sound guided learning progress.
/// Persists the highest unlocked level and per-level accuracy to UserDefaults.
@Observable
final class SProgressStore {
    /// The highest level unlocked (1–8). Level 1 is always unlocked.
    var highestUnlockedLevel: Int {
        didSet { defaults.set(highestUnlockedLevel, forKey: Keys.highestLevel) }
    }

    /// Per-level first-attempt accuracy (level number → 0.0–1.0).
    private(set) var levelAccuracy: [Int: Double] {
        didSet {
            if let data = try? JSONEncoder().encode(levelAccuracy) {
                defaults.set(data, forKey: Keys.levelAccuracy)
            }
        }
    }

    /// Per-level trial counts.
    private(set) var levelTrialCounts: [Int: Int] {
        didSet {
            if let data = try? JSONEncoder().encode(levelTrialCounts) {
                defaults.set(data, forKey: Keys.levelTrialCounts)
            }
        }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let highestLevel = "beemoo.s.highestUnlockedLevel"
        static let levelAccuracy = "beemoo.s.levelAccuracy"
        static let levelTrialCounts = "beemoo.s.levelTrialCounts"
    }

    init() {
        let stored = defaults.integer(forKey: Keys.highestLevel)
        self.highestUnlockedLevel = max(stored, 1)

        if let data = defaults.data(forKey: Keys.levelAccuracy),
           let decoded = try? JSONDecoder().decode([Int: Double].self, from: data) {
            self.levelAccuracy = decoded
        } else {
            self.levelAccuracy = [:]
        }

        if let data = defaults.data(forKey: Keys.levelTrialCounts),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            self.levelTrialCounts = decoded
        } else {
            self.levelTrialCounts = [:]
        }
    }

    /// Record a completed level's results and potentially unlock the next level.
    func recordLevelCompletion(
        level: Int,
        correctFirstAttempts: Int,
        totalTrials: Int,
        trialThreshold: Int,
        accuracyThreshold: Double
    ) {
        guard totalTrials > 0 else { return }

        let accuracy = Double(correctFirstAttempts) / Double(totalTrials)
        levelAccuracy[level] = accuracy
        levelTrialCounts[level] = totalTrials

        // Unlock next level if thresholds met
        if totalTrials >= trialThreshold && accuracy >= accuracyThreshold {
            if level >= highestUnlockedLevel && level < 8 {
                highestUnlockedLevel = level + 1
            }
        }
    }

    func isLevelUnlocked(_ level: Int) -> Bool {
        level <= highestUnlockedLevel
    }
}
