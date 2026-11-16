import SwiftUI

// MARK: - Layout

/// Landscape metrics for the "say the word" games (Monkey Climb, River Hop).
/// Left column = small BEEMOO + bubble on top, word panel below; the game scene owns the right side.
struct WordPracticeLayout {
    let size: CGSize

    /// iPhone landscape (short screens). Width can't tell iPhone apart: an iPhone 17 is ~874pt wide.
    var isCompact: Bool { size.height < 600 }

    var margin: CGFloat { isCompact ? 10 : 24 }
    /// Left column for the word panel
    var columnWidth: CGFloat { size.width * 0.40 - margin }
    /// Right edge of the word column; the scene should keep its hero right of this
    var columnMaxX: CGFloat { margin + columnWidth }

    var beemooSize: CGFloat { min(max(size.height * 0.15, 56), 120) }
    /// BEEMOO starts right of the runner's 44pt home button (RunnerChrome) so they never touch
    private var beemooLeft: CGFloat { isCompact ? 58 : 72 }
    var beemooCenter: CGPoint { CGPoint(x: beemooLeft + beemooSize / 2, y: margin + beemooSize / 2) }

    var bubbleLeft: CGFloat { beemooLeft + beemooSize + 2 }
    /// May run past the word column over the scene, so short lines like "Say the word!"
    /// stay on one line instead of growing off the top.
    var bubbleWidth: CGFloat { min(size.width * 0.46 - bubbleLeft, 300) }

    var speakerSize: CGFloat { isCompact ? 36 : 56 }
    var meterHeight: CGFloat { isCompact ? 34 : 48 }
    var controlGap: CGFloat { isCompact ? 8 : 18 }

    /// Everything below the BEEMOO row
    var panelRect: CGRect {
        let top = margin + beemooSize + (isCompact ? 6 : 16)
        return CGRect(x: margin, y: top, width: columnWidth, height: size.height - top - margin)
    }

    /// Height used by the speaker overhang and the listening meter below the card
    private var controlsHeight: CGFloat { speakerSize / 2 + controlGap + meterHeight }

    // Intro: big BEEMOO inside the word column, bubble above it, the start button below it.
    // Everything stays left of the scene's hero, on every screen size.
    var introBeemooSize: CGFloat { min(columnWidth * 0.6, size.height * 0.3) }
    var introBeemooCenter: CGPoint { CGPoint(x: margin + columnWidth / 2, y: size.height * 0.58) }
    /// The intro bubble stays below the runner's home button (14pt inset + 44pt)
    var introBubbleTop: CGFloat { 66 }
    var introBubbleWidth: CGFloat { min(columnWidth, 360) }
    var introButtonY: CGFloat { (introBeemooCenter.y + introBeemooSize / 2 + size.height - margin) / 2 }

    var cardSize: CGSize {
        let maxH = panelRect.height - controlsHeight
        let maxW = columnWidth * (isCompact ? 0.78 : 0.9)
        // Slightly taller than wide so the image stays square-ish above the word
        let h = min(maxH, maxW * 1.15)
        return CGSize(width: min(maxW, h / 1.15 * (isCompact ? 1.25 : 1)), height: h)
    }
}

// MARK: - Bubble

/// BEEMOO's bubble with a tail pointing left at BEEMOO. The bubble hugs its text up to `width`.
struct WordPracticeBubble: View {
    let vm: NarratedBubbleVM
    let width: CGFloat
    /// Where the tail's tip sits horizontally (just right of BEEMOO)
    let left: CGFloat
    let centerY: CGFloat

    /// During play: right of the small BEEMOO in the top-left corner
    init(vm: NarratedBubbleVM, layout: WordPracticeLayout) {
        self.init(vm: vm, width: layout.bubbleWidth, left: layout.bubbleLeft, centerY: layout.beemooCenter.y)
    }

    init(vm: NarratedBubbleVM, width: CGFloat, left: CGFloat, centerY: CGFloat) {
        self.vm = vm
        self.width = width
        self.left = left
        self.centerY = centerY
    }

    var body: some View {
        HStack(spacing: -2) {
            BubbleTail()
                .fill(.white)
                .overlay { BubbleTail().stroke(Color.bmYellow, lineWidth: 3) }
                .frame(width: 12, height: 18)
                .zIndex(1)
            NarratedBubble(vm: vm, contentWidth: width)
        }
        .frame(width: width + 10, alignment: .leading)
        .position(x: left + (width + 10) / 2, y: centerY)
    }
}

/// Intro bubble: centered in the word column, just above the big BEEMOO, tail pointing down at it.
/// It grows upward as words reveal, so it never covers BEEMOO.
struct WordPracticeIntroBubble: View {
    let vm: NarratedBubbleVM
    let layout: WordPracticeLayout

    var body: some View {
        let top = layout.introBeemooCenter.y - layout.introBeemooSize / 2 - 4
        VStack(spacing: -2) {
            NarratedBubble(vm: vm, contentWidth: layout.introBubbleWidth, centered: true)
            BubbleTail()
                .fill(.white)
                .overlay { BubbleTail().stroke(Color.bmYellow, lineWidth: 3) }
                .frame(width: 12, height: 18)
                .rotationEffect(.degrees(-90))
                .frame(width: 18, height: 12)
        }
        .frame(width: layout.columnWidth, height: top - layout.introBubbleTop, alignment: .bottom)
        .position(x: layout.introBeemooCenter.x, y: layout.introBubbleTop + (top - layout.introBubbleTop) / 2)
    }
}

/// Small left-pointing tail that connects the bubble to BEEMOO.
struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

// MARK: - Word panel

/// Word card (image, word inside, golden frame, speaker overlapping the bottom edge) above the
/// listening meter. The meter is read-only; only when speech recognition is unavailable does it
/// become the adult's "They said it" button.
struct WordPracticePanel: View {
    let stimulus: StimulusConfig
    let layout: WordPracticeLayout
    let recognizer: WordRecognizer
    let awaitingWord: Bool
    let onSpeaker: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        let compact = layout.isCompact
        let corner: CGFloat = compact ? 14 : 20

        VStack(spacing: 0) {
            VStack(spacing: compact ? 2 : 6) {
                RemoteImage(filename: stimulus.wordImage)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(stimulus.targetWord.capitalized)
                    .font(.baloo2(compact ? 18 : 30))
                    .foregroundStyle(Color.bmNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.top, compact ? 10 : 16)
            // Leave room so the word sits above the half of the speaker that overlaps the card
            .padding(.bottom, layout.speakerSize / 2 + (compact ? 2 : 6))
            .frame(width: layout.cardSize.width, height: layout.cardSize.height)
            .background(RoundedRectangle(cornerRadius: corner).fill(.white))
            .overlay { CardFrame(cornerRadius: corner, borderWidth: compact ? 5 : 8) }
            .bmCardShadow()
            .overlay(alignment: .bottom) {
                Button(action: onSpeaker) {
                    RemoteImage(filename: "ui/speaker_button.png")
                        .scaledToFit()
                        .frame(width: layout.speakerSize, height: layout.speakerSize)
                }
                .buttonStyle(.plain)
                .offset(y: layout.speakerSize / 2)
                .accessibilityLabel("Hear the word")
            }
            .padding(.bottom, layout.speakerSize / 2 + layout.controlGap)

            if recognizer.mode == .manual {
                Button(action: onConfirm) {
                    Label("They said it", systemImage: "checkmark")
                        .font(.nunito(compact ? 13 : 17, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, compact ? 14 : 20)
                        .frame(height: layout.meterHeight)
                        .background(Capsule().fill(Color.bmConceptGreen).bmCardShadow())
                }
                .buttonStyle(.plain)
                .disabled(!awaitingWord)
                .opacity(awaitingWord ? 1 : 0.5)
            } else {
                ListeningMeter(recognizer: recognizer, height: layout.meterHeight)
                    .opacity(awaitingWord ? 1 : 0.5)
            }
        }
        .frame(width: layout.columnWidth, height: layout.panelRect.height)
        .position(x: layout.panelRect.midX, y: layout.panelRect.midY)
    }
}

// MARK: - Skip

/// Skip lives in the bottom-right corner, away from the word panel.
struct WordPracticeSkipButton: View {
    let layout: WordPracticeLayout
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        let compact = layout.isCompact
        Button(action: action) {
            HStack(spacing: 4) {
                Text("Skip")
                Image(systemName: "forward.fill")
                    .font(.system(size: compact ? 11 : 14, weight: .bold))
            }
            .font(.nunito(compact ? 14 : 18, weight: .bold))
            .foregroundStyle(Color.bmNavy)
            .padding(.horizontal, compact ? 14 : 20)
            .padding(.vertical, compact ? 7 : 10)
            .background(Capsule().fill(.white.opacity(0.9)).bmCardShadow())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(layout.margin)
    }
}

// MARK: - Listening meter

/// Live mic level bars. Shows the child (and adult) that the app is actually hearing them.
struct ListeningMeter: View {
    let recognizer: WordRecognizer
    let height: CGFloat

    /// Fixed per-bar shape so the bars read as a waveform, tallest in the middle
    private let weights: [CGFloat] = [0.45, 0.7, 0.9, 1, 0.9, 0.7, 0.45]

    var body: some View {
        let listening = recognizer.isListening
        let level = CGFloat(recognizer.level)
        let barMax = height * 0.55

        HStack(spacing: height * 0.22) {
            Image(systemName: "mic.fill")
                .font(.system(size: height * 0.4, weight: .semibold))
                .foregroundStyle(listening ? Color.bmBlue : Color.bmNavy50)

            HStack(spacing: height * 0.09) {
                ForEach(weights.indices, id: \.self) { i in
                    Capsule()
                        .fill(listening ? Color.bmBlue : Color.bmNavy50.opacity(0.5))
                        .frame(width: height * 0.1, height: max(height * 0.1, barMax * weights[i] * level))
                }
            }
            .frame(height: barMax)
            .animation(.easeOut(duration: 0.08), value: level)
        }
        .padding(.horizontal, height * 0.45)
        .frame(height: height)
        .background(Capsule().fill(.white.opacity(0.92)).bmCardShadow())
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(listening ? "Listening" : "Microphone off")
    }
}
