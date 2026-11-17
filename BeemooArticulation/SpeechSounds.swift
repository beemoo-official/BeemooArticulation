import SwiftUI

/// A speech sound the child can practice, and the themed world its games live in
/// (S → jungle, R → space, …). Only live sounds can be opened; the rest show as "coming soon".
struct SpeechSound: Identifiable {
    let id: String
    /// What the child sees on the tile: "S", "SH", …
    let letter: String
    /// One-word world name: "Jungle"
    let world: String
    /// Placeholder picture until each world has its own art
    let emoji: String
    /// World art from the backend, used instead of the emoji when present
    var art: String? = nil
    let face: Color
    let side: Color
    var isLive = false
}

extension SpeechSound {
    static let all: [SpeechSound] = [
        SpeechSound(id: "s", letter: "S", world: "Jungle", emoji: "🐍",
                    art: "s-sound/level1/BEEMOO_S_Sound_Snake.png",
                    face: Color(hex: "3EAA4F"), side: Color(hex: "23753A"), isLive: true),
        SpeechSound(id: "r", letter: "R", world: "Space", emoji: "🚀",
                    face: Color(hex: "E9503F"), side: Color(hex: "A8302A")),
        SpeechSound(id: "l", letter: "L", world: "Ocean", emoji: "🐠",
                    face: Color(hex: "1E9BE0"), side: Color(hex: "136AA0")),
        SpeechSound(id: "k", letter: "C", world: "Castle", emoji: "🏰",
                    face: Color(hex: "8B5CF6"), side: Color(hex: "5B36B5")),
        SpeechSound(id: "j", letter: "J", world: "Candy", emoji: "🍭",
                    face: Color(hex: "F062A6"), side: Color(hex: "B03A75")),
        SpeechSound(id: "sh", letter: "SH", world: "Beach", emoji: "🐚",
                    face: Color(hex: "F2A93B"), side: Color(hex: "B8741A")),
        SpeechSound(id: "ch", letter: "CH", world: "Train", emoji: "🚂",
                    face: Color(hex: "14B8A6"), side: Color(hex: "0E7C70")),
        SpeechSound(id: "th", letter: "TH", world: "Storm", emoji: "⛈️",
                    face: Color(hex: "5B6CD8"), side: Color(hex: "3A47A0")),
    ]
}
