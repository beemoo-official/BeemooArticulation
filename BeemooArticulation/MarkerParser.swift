import SwiftUI

enum MarkerParser {
    /// Parses `*word*` markers into an AttributedString where marked runs
    /// render in concept green (#1F8A48) at the same weight as the surrounding text.
    /// Default ink is navy on cream prompt plate.
    static func parse(
        _ text: String,
        font: Font = .nunito(36, weight: .bold),
        ink: Color = .bmNavy
    ) -> AttributedString {
        var result = AttributedString()
        var remaining = text[...]

        while let starStart = remaining.firstIndex(of: "*") {
            let before = remaining[remaining.startIndex..<starStart]
            if !before.isEmpty {
                var run = AttributedString(before)
                run.font = font
                run.foregroundColor = ink
                result.append(run)
            }

            let afterStar = remaining.index(after: starStart)
            guard afterStar < remaining.endIndex,
                  let starEnd = remaining[afterStar...].firstIndex(of: "*") else {
                let rest = remaining[starStart...]
                var run = AttributedString(rest)
                run.font = font
                run.foregroundColor = ink
                result.append(run)
                remaining = remaining[remaining.endIndex...]
                break
            }

            let markedWord = remaining[afterStar..<starEnd]
            var run = AttributedString(markedWord)
            run.font = font
            run.foregroundColor = .bmConceptGreen
            result.append(run)

            remaining = remaining[remaining.index(after: starEnd)...]
        }

        if !remaining.isEmpty {
            var run = AttributedString(remaining)
            run.font = font
            run.foregroundColor = ink
            result.append(run)
        }

        return result
    }
}
