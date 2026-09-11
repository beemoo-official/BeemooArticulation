import SwiftUI

// MARK: - Word token

struct WordToken: Identifiable {
    let id: Int
    let text: String
    let isMarked: Bool
    let trailingSpace: Bool
}

// MARK: - Tokenizer

extension MarkerParser {
    static func tokenize(_ markerText: String) -> [WordToken] {
        var tokens: [WordToken] = []
        var id = 0
        var remaining = markerText[...]

        while !remaining.isEmpty {
            if remaining.first == "*" {
                let afterStar = remaining.index(after: remaining.startIndex)
                guard afterStar < remaining.endIndex,
                      let closeIdx = remaining[afterStar...].firstIndex(of: "*") else { break }
                let word = String(remaining[afterStar..<closeIdx])
                let afterClose = remaining.index(after: closeIdx)
                remaining = afterClose < remaining.endIndex ? remaining[afterClose...] : remaining[remaining.endIndex...]

                let subwords = word.split(separator: " ", omittingEmptySubsequences: true)
                for (i, sw) in subwords.enumerated() {
                    let trailing = i < subwords.count - 1 || (!remaining.isEmpty && remaining.first == " ")
                    tokens.append(WordToken(id: id, text: String(sw), isMarked: true, trailingSpace: trailing))
                    id += 1
                }
                if remaining.first == " " {
                    remaining = remaining.dropFirst()
                    if let last = tokens.last, !last.trailingSpace {
                        tokens[tokens.count - 1] = WordToken(id: last.id, text: last.text, isMarked: last.isMarked, trailingSpace: true)
                    }
                }
            } else {
                let segEnd = remaining.firstIndex(of: "*") ?? remaining.endIndex
                let segment = String(remaining[remaining.startIndex..<segEnd])
                remaining = segEnd < remaining.endIndex ? remaining[segEnd...] : remaining[remaining.endIndex...]

                let words = segment.split(separator: " ", omittingEmptySubsequences: true)
                for (i, w) in words.enumerated() {
                    let trailing = i < words.count - 1 || (!remaining.isEmpty)
                    tokens.append(WordToken(id: id, text: String(w), isMarked: false, trailingSpace: trailing))
                    id += 1
                }
            }
        }
        return tokens
    }
}

// MARK: - Bubble view model

@Observable
final class NarratedBubbleVM {
    let tokens: [WordToken]
    let narrationTrack: NarrationTrack
    let markerText: String
    var revealedCount: Int = 0
    var narrationFinished: Bool = false
    var isNarrationOff: Bool = false

    init(markerText: String, narrationTrack: NarrationTrack) {
        self.markerText = markerText
        self.tokens = MarkerParser.tokenize(markerText)
        self.narrationTrack = narrationTrack
    }

    func startNarration() {
        guard !isNarrationOff else {
            revealedCount = tokens.count
            narrationFinished = true
            return
        }

        revealedCount = 0
        narrationFinished = false

        let stripped = StrippedText(from: markerText)
        var wordIndex = 0

        narrationTrack.speak(stripped.stripped, onWord: { [weak self] range in
            guard let self else { return }
            if wordIndex < self.tokens.count {
                wordIndex += 1
                self.revealedCount = wordIndex
            }
        }, onFinish: { [weak self] in
            guard let self else { return }
            self.revealedCount = self.tokens.count
            self.narrationFinished = true
        })
    }

    func revealAll() {
        narrationTrack.stop()
        revealedCount = tokens.count
        narrationFinished = true
    }

    /// AttributedString of only the revealed tokens.
    /// At a fixed container width, words land at the same positions
    /// as the full sentence — line breaks are determined by width, not content end.
    func revealedAttributedString(font: Font) -> AttributedString {
        var result = AttributedString()
        let revealed = tokens.prefix(revealedCount)
        for token in revealed {
            var str = token.text
            if token.trailingSpace { str += " " }
            var run = AttributedString(str)
            run.font = font
            run.foregroundColor = token.isMarked ? .bmConceptGreen : .bmNavy
            result.append(run)
        }
        // If nothing revealed, use a space to keep minimum size
        if result.characters.isEmpty {
            var space = AttributedString(" ")
            space.font = font
            space.foregroundColor = .clear
            result = space
        }
        return result
    }
}

// MARK: - Narrated bubble view

struct NarratedBubble: View {
    let vm: NarratedBubbleVM
    /// Fixed width the text wraps at. Must not change between reveals.
    let contentWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let bubbleFont: Font = .baloo2(22)

    var body: some View {
        HStack {
            Text(vm.revealedAttributedString(font: bubbleFont))
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.bmYellow, lineWidth: 4)
                        }
                }

            // Reserve 40% so the bubble never exceeds 60%
            Spacer(minLength: 0)
        }
        .frame(width: contentWidth)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.22), value: vm.revealedCount)
    }
}
