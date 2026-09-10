import SwiftUI

enum MarkerParser {
    /// Parses `*word*` markers into an AttributedString where marked runs
    /// render in concept green (#1F8A48) at the same weight as surrounding text.
    static func parse(_ text: String, font: Font = .nunito(24, weight: .bold)) -> AttributedString {
        var result = AttributedString()
        var remaining = text[...]

        while let starStart = remaining.firstIndex(of: "*") {
            // Append everything before the star
            let before = remaining[remaining.startIndex..<starStart]
            if !before.isEmpty {
                var run = AttributedString(before)
                run.font = font
                run.foregroundColor = .white
                result.append(run)
            }

            // Find closing star
            let afterStar = remaining.index(after: starStart)
            guard afterStar < remaining.endIndex,
                  let starEnd = remaining[afterStar...].firstIndex(of: "*") else {
                // No closing star — treat rest as plain text
                let rest = remaining[starStart...]
                var run = AttributedString(rest)
                run.font = font
                run.foregroundColor = .white
                result.append(run)
                remaining = remaining[remaining.endIndex...]
                break
            }

            // Append marked word in concept green
            let markedWord = remaining[afterStar..<starEnd]
            var run = AttributedString(markedWord)
            run.font = font
            run.foregroundColor = .bmConceptGreen
            result.append(run)

            remaining = remaining[remaining.index(after: starEnd)...]
        }

        // Append any remaining text after the last marker
        if !remaining.isEmpty {
            var run = AttributedString(remaining)
            run.font = font
            run.foregroundColor = .white
            result.append(run)
        }

        return result
    }
}
