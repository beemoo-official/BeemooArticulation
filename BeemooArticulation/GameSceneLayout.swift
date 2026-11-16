import SwiftUI

// MARK: - Layout

/// Landscape metrics shared by the BEEMOO mini-games (Make the S Sound, Hear the S Sound).
/// Game phase: small BEEMOO + bubble in a row at the top (clear of the runner's home button),
/// the game filling the area below. Intro/celebration: big BEEMOO centered, bubble above it,
/// the action button below it.
struct GameSceneLayout {
    let size: CGSize

    /// iPhone landscape (short screens)
    var isCompact: Bool { size.height < 600 }
    var margin: CGFloat { isCompact ? 10 : 24 }

    // Game phase: top row
    var beemooSize: CGFloat { min(max(size.height * 0.15, 56), 120) }
    /// BEEMOO starts right of the runner's 44pt home button (RunnerChrome)
    private var beemooLeft: CGFloat { isCompact ? 58 : 72 }
    /// Tall enough for a two-line bubble next to BEEMOO
    private var rowHeight: CGFloat { max(beemooSize, isCompact ? 76 : 100) }
    var beemooCenter: CGPoint { CGPoint(x: beemooLeft + beemooSize / 2, y: margin + rowHeight / 2) }
    var bubbleLeft: CGFloat { beemooLeft + beemooSize + 2 }
    var bubbleWidth: CGFloat { min(size.width - bubbleLeft - 100, 560) }

    /// Everything below BEEMOO's row, down to the bottom margin
    var gameRect: CGRect {
        let top = margin + rowHeight + (isCompact ? 4 : 12)
        return CGRect(x: 0, y: top, width: size.width, height: size.height - margin - top)
    }

    // Intro / celebration
    var heroSize: CGSize { CGSize(width: size.width * 0.34, height: size.height * 0.5) }
    var heroCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.52) }
    var heroTop: CGFloat { heroCenter.y - heroSize.height / 2 }
    var heroBubbleWidth: CGFloat { min(size.width * 0.6, 480) }
    var actionY: CGFloat { size.height - margin - 26 - (isCompact ? 0 : 16) }
}

// MARK: - Speech bubble

/// BEEMOO's speech bubble with a tail pointing at BEEMOO: above the big centered BEEMOO
/// (`heroPose`), or to the right of the small one in the top row.
struct BeemooSpeechBubble: View {
    let vm: NarratedBubbleVM
    let layout: GameSceneLayout
    let heroPose: Bool

    var body: some View {
        if heroPose {
            // Bottom of the bubble sits just above BEEMOO's head, tail pointing down at it
            VStack(spacing: -2) {
                NarratedBubble(vm: vm, contentWidth: layout.heroBubbleWidth, centered: true)
                tail
                    .frame(width: 12, height: 18)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18, height: 12)
            }
            .frame(width: layout.size.width, height: layout.heroTop - 4, alignment: .bottom)
            .position(x: layout.size.width / 2, y: (layout.heroTop - 4) / 2)
        } else {
            HStack(spacing: -2) {
                tail
                    .frame(width: 12, height: 18)
                    .zIndex(1)
                NarratedBubble(vm: vm, contentWidth: layout.bubbleWidth)
            }
            .frame(width: layout.bubbleWidth + 10, alignment: .leading)
            .position(x: layout.bubbleLeft + (layout.bubbleWidth + 10) / 2, y: layout.beemooCenter.y)
        }
    }

    private var tail: some View {
        SpeechTail()
            .fill(.white)
            .overlay { SpeechTail().stroke(Color.bmYellow, lineWidth: 3) }
    }
}

/// Small left-pointing tail that connects a bubble to BEEMOO.
private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
