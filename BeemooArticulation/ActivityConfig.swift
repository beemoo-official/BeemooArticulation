import Foundation

// MARK: - Activity config (loaded from per-activity JSON)

struct ActivityConfig: Codable, Sendable, Identifiable {
    let activityId: String
    var id: String { activityId }
    let version: Int
    let title: String
    let umbrella: String
    let orientation: String
    let concepts: [String]
    let screens: [ScreenConfig]
}

// MARK: - Screen config

struct ScreenConfig: Codable, Sendable, Identifiable {
    let n: Int
    let type: ScreenType
    let concept: String

    // intro / teaching
    let text: String?
    let scene: String?
    let audio: String?
    let note: String?

    // teaching
    let ringXPercent: Int?
    let ringYPercent: Int?

    // comparison
    let lines: [String]?
    let labels: [String]?
    let cuesXPercent: [Int]?
    let cueTopPercent: Int?

    // receptive
    let prompt: String?
    let correct: String?
    let choices: [ChoiceConfig]?
    let shuffleChoices: Bool?

    // transition / soundModeling variant
    let variant: Int?

    // soundModeling (Level 1)
    let spotXPercent: Int?
    let spotYPercent: Int?

    // soundDiscrimination (Level 2)
    let targetAsset: String?
    let distractorAssets: [String]?

    // wordProduction / sentenceProduction / flashcard (Levels 3-8)
    let stimuli: [StimulusConfig]?

    var id: Int { n }

    var sceneName: String? {
        scene.map { String($0.dropLast(4)) } // "scene3.jpg" → "scene3"
    }

    var displayText: String? {
        text ?? prompt
    }
}

// MARK: - Screen type

enum ScreenType: String, Codable, Sendable {
    case intro
    case teaching
    case comparison
    case receptive
    case transition
    case celebration
    // /s/ articulation module
    case soundModeling
    case soundDiscrimination
    case wordProduction
    case sentenceProduction
    case flashcard
}

// MARK: - Choice config

struct ChoiceConfig: Codable, Sendable, Identifiable {
    let asset: String
    let meaning: String

    var id: String { asset }

    var assetName: String {
        String(asset.dropLast(4)) // "p7_0.jpg" → "p7_0"
    }
}

// MARK: - Stimulus config (for articulation production screens)

struct StimulusConfig: Codable, Sendable, Identifiable {
    let stimulusId: String
    let targetWord: String
    let targetPosition: String   // "initial", "final", "medial"
    let wordImage: String
    let sentenceText: String?
    let sentenceImage: String?
    let audioText: String?       // text for TTS or audio filename

    var id: String { stimulusId }

    var wordImageName: String {
        String(wordImage.dropLast(4))
    }

    var sentenceImageName: String? {
        sentenceImage.map { String($0.dropLast(4)) }
    }
}

// MARK: - Loader

extension SeedData {
    static func loadActivityConfig(_ name: String) -> ActivityConfig {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(ActivityConfig.self, from: data) else {
            fatalError("Could not load \(name).json from bundle")
        }
        return config
    }
}
