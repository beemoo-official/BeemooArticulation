import Foundation

// MARK: - Trial record

struct TrialRecord: Sendable, Codable {
    let id: UUID
    let screenId: Int
    let activityId: String
    let concept: String
    var firstTry: Bool
    var attempts: Int
    let timestamp: Date

    // Articulation-specific fields
    var stimulusId: String?
    var targetWord: String?
    var targetPosition: String?        // "initial" / "final" / "medial"
    var stimulusType: String?          // "word" / "sentence"
    var firstAttemptOutcome: String?   // "correct" / "incorrect" / "skip"
    var retryPrompted: Bool?
    var retryOutcome: String?          // "correct" / "incorrect" / "skip"
    var level: Int?
}

// MARK: - Protocol boundary for future API integration

protocol TrialLogging: Sendable {
    func log(_ record: TrialRecord)
    func records() -> [TrialRecord]
}

// MARK: - In-memory implementation

@Observable
final class TrialLogger: TrialLogging {
    private var _records: [TrialRecord] = []

    func log(_ record: TrialRecord) {
        _records.append(record)
    }

    func records() -> [TrialRecord] {
        _records
    }
}
