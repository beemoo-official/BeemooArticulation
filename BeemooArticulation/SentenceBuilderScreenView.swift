import SwiftUI
import UIKit

/// Levels 6-8 — Make the Sentence.
/// Each trial: BEEMOO models the sentence → the child drags shuffled word cards into the slots
/// (wrong drops bounce back) → "Great! Now say the whole sentence!" → the adult taps ✓ or ✗ →
/// the picture pops in and Next unlocks. After the last sentence, leaves cover the screen and the
/// child swipes them away to find a surprise jungle animal.
/// Completed trials (progress dots) are tracked separately from accuracy (the trial log).
struct SentenceBuilderScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @Environment(APIClient.self) private var apiClient

    @State private var index = 0
    @State private var phase: Phase = .modeling
    @State private var trialId = UUID()
    @State private var cards: [WordCard] = []
    /// slot index → id of the card sitting in it
    @State private var placed: [Int: Int] = [:]
    @State private var dragOffset: [Int: CGSize] = [:]
    @State private var completed = 0
    @State private var lastCorrect = false
    @State private var animal: SurpriseAnimal?
    @State private var animalRevealed = false

    @State private var bubbleVM: NarratedBubbleVM?
    /// Measured, so a tall bubble is pushed down instead of running off the top
    @State private var bubbleHeight: CGFloat = 0
    /// BEEMOO's voice: pre-recorded clips (voice/beemoo/…), falling back to the system voice. Set on appear.
    @State private var narrationTrack: any NarrationTrack = SystemNarrationTrack()
    @State private var sfx = RemoteAudioPlayer()

    enum Phase { case modeling, building, speaking, reward, surprise }

    private var stimuli: [StimulusConfig] { screen.stimuli ?? [] }
    private var current: StimulusConfig? { index < stimuli.count ? stimuli[index] : nil }
    /// The sentence with the target word marked, e.g. "The *sock* is red."
    private var sentence: String { current.map { $0.sentenceText ?? $0.audioText ?? $0.targetWord } ?? "" }
    private var words: [WordCard] { WordCard.parse(sentence) }

    var body: some View {
        GeometryReader { geo in
            let layout = SentenceBuilderLayout(size: geo.size, wordCount: max(words.count, 1))
            ZStack {
                if phase == .surprise, let animal {
                    LeafRevealView(animal: animal) { revealAnimal(animal) }
                        .transition(.opacity)
                } else {
                    tray(layout)
                    cardLayer(layout)
                        .id(index)
                        .transition(.opacity)
                    if phase == .reward, let stimulus = current {
                        rewardPicture(stimulus, layout: layout)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                    bottomBar(layout)
                }

                beemoo(layout)
                if let vm = bubbleVM {
                    bubble(vm: vm, layout: layout)
                }

                if phase == .surprise {
                    surpriseOverlay(layout)
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
            narrationTrack = VoiceClipNarrationTrack(apiClient: apiClient)
            startTrial()
        }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - BEEMOO + bubble

    private func beemoo(_ layout: SentenceBuilderLayout) -> some View {
        let happy = (phase == .reward && lastCorrect) || animalRevealed
        return RemoteImage(filename: happy ? "mascot/BEEMOO_04_Smiling_Happy.png" : "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(width: layout.beemooSize, height: layout.beemooSize)
            .position(layout.beemooCenter)
            .allowsHitTesting(false)
    }

    /// Bubble right of BEEMOO with a replay speaker on its right edge. Narrower while the picture shows.
    private func bubble(vm: NarratedBubbleVM, layout: SentenceBuilderLayout) -> some View {
        let width = layout.bubbleWidth(beside: phase == .reward ? layout.pictureRect : (phase == .surprise && !animalRevealed ? layout.hintRect : nil))
        let showSpeaker = phase != .surprise
        return HStack(spacing: -2) {
            BubbleTail()
                .fill(.white)
                .overlay { BubbleTail().stroke(Color.bmYellow, lineWidth: 3) }
                .frame(width: 12, height: 18)
                .zIndex(1)
            NarratedBubble(vm: vm, contentWidth: width)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { bubbleHeight = $0 }
            if showSpeaker {
                speakerButton(layout)
                    .padding(.leading, 10)
            }
        }
        .frame(width: width + 10 + (showSpeaker ? layout.speakerSize + 10 : 0), alignment: .leading)
        .position(
            x: layout.bubbleLeft + (width + 10 + (showSpeaker ? layout.speakerSize + 10 : 0)) / 2,
            y: max(layout.beemooCenter.y, layout.margin + bubbleHeight / 2)
        )
    }

    private func speakerButton(_ layout: SentenceBuilderLayout) -> some View {
        Button {
            narrationTrack.speak(sentence, onWord: { _ in }, onFinish: {})
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: layout.speakerSize * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: layout.speakerSize, height: layout.speakerSize)
                .background(Circle().fill(Color.bmBlue))
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .bmFloatingControlShadow()
        }
        .buttonStyle(.plain)
        // While BEEMOO models the sentence, a replay would cut off the bubble's narration
        .disabled(phase == .modeling)
        .opacity(phase == .modeling ? 0.5 : 1)
    }

    // MARK: - Tray + cards

    private func tray(_ layout: SentenceBuilderLayout) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.trayRadius)
                .fill(LinearGradient(colors: [Color(hex: "F2B85A"), Color(hex: "D98E35")], startPoint: .top, endPoint: .bottom))
                .overlay {
                    RoundedRectangle(cornerRadius: layout.trayRadius)
                        .stroke(Color(hex: "A8621E"), lineWidth: layout.isCompact ? 3 : 5)
                }
                .frame(width: layout.trayRect.width, height: layout.trayRect.height)
                .position(x: layout.trayRect.midX, y: layout.trayRect.midY)
                .bmCardShadow()

            ForEach(0..<words.count, id: \.self) { slot in
                RoundedRectangle(cornerRadius: layout.cardRadius)
                    .fill(Color.bmCream.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: layout.cardRadius)
                            .strokeBorder(Color(hex: "8A5A2B").opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                    }
                    .frame(width: layout.slotWidth, height: layout.slotHeight)
                    .position(layout.slotCenter(slot))
            }
        }
        .allowsHitTesting(false)
    }

    private func cardLayer(_ layout: SentenceBuilderLayout) -> some View {
        ZStack {
            ForEach(cards) { card in
                let slot = placed.first(where: { $0.value == card.id })?.key
                let offset = dragOffset[card.id] ?? .zero
                let home = slot.map(layout.slotCenter) ?? layout.homeCenter(card.home)
                cardView(card, inSlot: slot != nil, lifted: offset != .zero, layout: layout)
                    .position(x: home.x + offset.width, y: home.y + offset.height)
                    .zIndex(offset != .zero ? 2 : (slot != nil ? 0 : 1))
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                guard phase == .building, slot == nil else { return }
                                dragOffset[card.id] = value.translation
                            }
                            .onEnded { value in
                                guard phase == .building, slot == nil else { return }
                                let base = layout.homeCenter(card.home)
                                drop(card, at: CGPoint(x: base.x + value.translation.width, y: base.y + value.translation.height), layout: layout)
                            }
                    )
                    .allowsHitTesting(phase == .building && slot == nil)
            }
        }
    }

    private func cardView(_ card: WordCard, inSlot: Bool, lifted: Bool, layout: SentenceBuilderLayout) -> some View {
        Text(card.text)
            .font(.baloo2(layout.cardFontSize))
            .foregroundStyle(inSlot && card.isTarget ? Color.bmSentenceRed : Color.bmNavy)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 8)
            .frame(width: layout.slotWidth, height: layout.slotHeight)
            .background(
                RoundedRectangle(cornerRadius: layout.cardRadius)
                    .fill(Color.bmCream)
            )
            .overlay {
                RoundedRectangle(cornerRadius: layout.cardRadius)
                    .strokeBorder(Color(hex: "6DB34F"), lineWidth: layout.isCompact ? 3 : 4)
            }
            .scaleEffect(lifted ? 1.08 : 1)
            .shadow(color: .black.opacity(lifted ? 0.28 : 0.16), radius: lifted ? 10 : 4, y: lifted ? 6 : 2)
            .animation(.spring(duration: 0.2), value: lifted)
    }

    /// A card only sticks in the slot that holds its word; anywhere else it springs back home.
    private func drop(_ card: WordCard, at point: CGPoint, layout: SentenceBuilderLayout) {
        if let slot = layout.slot(at: point), placed[slot] == nil, words[slot].text == card.text {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                placed[slot] = card.id
                dragOffset[card.id] = nil
            }
            sfx.play("sfx/popEffect.mp3", from: apiClient)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if placed.count == words.count { sentenceBuilt() }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(duration: 0.45, bounce: 0.35)) {
                dragOffset[card.id] = nil
            }
        }
    }

    // MARK: - Reward picture

    private func rewardPicture(_ stimulus: StimulusConfig, layout: SentenceBuilderLayout) -> some View {
        let rect = layout.pictureRect
        return ZStack {
            RemoteImage(filename: stimulus.sentenceImage ?? stimulus.wordImage)
                .scaledToFit()
                .padding(layout.isCompact ? 4 : 8)
                .frame(width: rect.width, height: rect.height)
                .background(RoundedRectangle(cornerRadius: layout.cardRadius).fill(.white))
                .clipShape(RoundedRectangle(cornerRadius: layout.cardRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: layout.cardRadius)
                        .stroke(Color.bmYellow, lineWidth: layout.isCompact ? 4 : 6)
                }
                .shadow(color: Color.bmYellow.opacity(lastCorrect ? 0.9 : 0.5), radius: lastCorrect ? 22 : 12)

            if lastCorrect {
                ForEach(Array(SparkleStar.around.enumerated()), id: \.offset) { _, star in
                    Image(systemName: "star.fill")
                        .font(.system(size: rect.height * star.size))
                        .foregroundStyle(Color.bmYellow)
                        .shadow(color: .orange.opacity(0.5), radius: 2)
                        .offset(x: rect.width * star.x, y: rect.height * star.y)
                }
            }
        }
        .position(x: rect.midX, y: rect.midY)
        .allowsHitTesting(false)
    }

    // MARK: - Bottom bar (progress, adult scoring, Next)

    private func bottomBar(_ layout: SentenceBuilderLayout) -> some View {
        let h = layout.barHeight
        let scoring = phase == .speaking
        let nextEnabled = phase == .reward
        return HStack(spacing: layout.isCompact ? 10 : 18) {
            progress(layout)

            // Adult scoring: reserved space so nothing shifts when it appears
            HStack(spacing: layout.isCompact ? 8 : 12) {
                scoreButton(icon: "checkmark", color: Color.bmConceptGreen, size: h) { score(correct: true) }
                scoreButton(icon: "xmark", color: Color.bmSentenceRed, size: h) { score(correct: false) }
            }
            .opacity(scoring ? 1 : 0)
            .allowsHitTesting(scoring)

            Button { nextSentence() } label: {
                HStack(spacing: 4) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                        .font(.system(size: h * 0.32, weight: .heavy))
                }
                .font(.baloo2(h * 0.42))
                .foregroundStyle(Color.bmNavy.opacity(nextEnabled ? 1 : 0.3))
                .padding(.horizontal, h * 0.45)
                .frame(height: h)
                .background(Capsule().fill(nextEnabled ? Color.bmYellow : .white.opacity(0.7)))
                .overlay { Capsule().stroke(.white, lineWidth: 2) }
                .bmFloatingControlShadow()
            }
            .buttonStyle(.plain)
            .disabled(!nextEnabled)
            // Hidden until the sentence is built, as in the reference screens
            .opacity(phase == .modeling || phase == .building ? 0 : 1)
        }
        .position(x: layout.size.width / 2, y: layout.barCenterY)
    }

    private func progress(_ layout: SentenceBuilderLayout) -> some View {
        let h = layout.barHeight
        let dot = h * (layout.isCompact ? 0.3 : 0.32)
        return HStack(spacing: h * 0.22) {
            VStack(spacing: -h * 0.08) {
                Text("Sentence")
                    .font(.baloo2(h * 0.26))
                Text("\(min(index + 1, stimuli.count)) of \(stimuli.count)")
                    .font(.baloo2(h * 0.32))
            }
            .foregroundStyle(Color.bmNavy)
            .fixedSize()

            Rectangle()
                .fill(Color(hex: "A8621E").opacity(0.6))
                .frame(width: 2, height: h * 0.55)

            HStack(spacing: dot * 0.35) {
                ForEach(0..<stimuli.count, id: \.self) { i in
                    Circle()
                        .fill(i < completed ? Color.bmConceptGreen : Color.bmNavy.opacity(0.22))
                        .overlay { Circle().stroke(.white, lineWidth: i < completed ? 2 : 0) }
                        .frame(width: dot, height: dot)
                }
            }
        }
        .padding(.horizontal, h * 0.3)
        .frame(height: h)
        .background(Capsule().fill(Color.bmCream.opacity(0.95)))
        .overlay { Capsule().stroke(Color(hex: "D98E35"), lineWidth: 2) }
        .bmFloatingControlShadow()
    }

    private func scoreButton(icon: String, color: Color, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(color))
                .overlay { Circle().stroke(.white, lineWidth: 3) }
                .bmFloatingControlShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Surprise (leaf wipe)

    private func surpriseOverlay(_ layout: SentenceBuilderLayout) -> some View {
        ZStack {
            if !animalRevealed {
                swipeHint(layout)
                    .position(x: layout.hintRect.midX, y: layout.hintRect.midY)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            } else {
                Button { onAdvance() } label: {
                    Text("Finish")
                        .font(.baloo2(layout.isCompact ? 22 : 28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, layout.isCompact ? 10 : 14)
                        .background(Capsule().fill(Color.bmConceptGreen))
                        .overlay { Capsule().stroke(.white, lineWidth: 3) }
                        .bmRaisedShadow()
                }
                .buttonStyle(.plain)
                .position(x: layout.size.width - layout.margin - (layout.isCompact ? 60 : 80), y: layout.barCenterY)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func swipeHint(_ layout: SentenceBuilderLayout) -> some View {
        let rect = layout.hintRect
        return VStack(spacing: rect.height * 0.04) {
            Text("Swipe the leaves to reveal your surprise!")
                .font(.baloo2(layout.isCompact ? 15 : 22))
                .foregroundStyle(Color.bmNavy)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            SwipeHandHint(size: rect.height * 0.38)
        }
        .padding(layout.isCompact ? 8 : 14)
        .frame(width: rect.width, height: rect.height)
        .background(RoundedRectangle(cornerRadius: layout.cardRadius).fill(Color.bmYellow.opacity(0.95)))
        .overlay { RoundedRectangle(cornerRadius: layout.cardRadius).stroke(.white, lineWidth: 3) }
        .bmRaisedShadow()
    }

    // MARK: - Trial flow

    private func startTrial() {
        let parsed = words
        let n = parsed.count
        var homes = Array(0..<n)
        // Never hand the child the sentence already in order
        if n > 1 { while homes == Array(0..<n) { homes.shuffle() } }
        cards = parsed.enumerated().map { i, w in WordCard(id: i, text: w.text, isTarget: w.isTarget, home: homes[i]) }
        placed = [:]
        dragOffset = [:]
        trialId = UUID()
        phase = .modeling

        // BEEMOO models the whole sentence before any card can move; only the first trial explains the task
        let line = index == 0 ? "Move the words to make the sentence. \(sentence)" : sentence
        say(line) {
            if phase == .modeling { phase = .building }
        }
    }

    private func sentenceBuilt() {
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(duration: 0.35)) { phase = .speaking }
            say("Great! Now say the whole sentence!")
        }
    }

    /// One adult decision per sentence. Either answer completes the trial; accuracy goes to the log.
    private func score(correct: Bool) {
        guard phase == .speaking, let stimulus = current else { return }
        trialLogger.log(TrialRecord(
            id: trialId, screenId: screen.n, activityId: activityId,
            concept: screen.concept, firstTry: true, attempts: 1, timestamp: Date(),
            stimulusId: stimulus.stimulusId, targetWord: stimulus.targetWord,
            targetPosition: stimulus.targetPosition, stimulusType: "sentence",
            firstAttemptOutcome: correct ? "correct" : "incorrect"
        ))
        lastCorrect = correct
        if correct {
            sfx.play("sfx/correct.mp3", from: apiClient)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        withAnimation(.spring(duration: 0.55, bounce: 0.45)) {
            completed += 1
            phase = .reward
        }
        say((correct ? "Awesome! " : "Nice try! ") + sentence)
    }

    private func nextSentence() {
        guard phase == .reward else { return }
        narrationTrack.stop()
        if index + 1 < stimuli.count {
            withAnimation(.easeOut(duration: 0.25)) {
                index += 1
                bubbleVM = nil
            }
            startTrial()
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                animal = SurpriseAnimal.next()
                phase = .surprise
            }
            say("You did it! You said \(stimuli.count) sentences! Swipe the leaves to reveal your surprise!")
        }
    }

    private func revealAnimal(_ animal: SurpriseAnimal) {
        sfx.play("sfx/correct.mp3", from: apiClient)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(duration: 0.5)) { animalRevealed = true }
        say("You found \(animal.article) \(animal.name)!")
    }

    // MARK: - Narration

    private func say(_ text: String, then: (() -> Void)? = nil) {
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        bubbleVM = vm
        vm.startNarration()
        guard let then else { return }
        Task {
            while bubbleVM === vm && !vm.narrationFinished {
                try? await Task.sleep(for: .milliseconds(50))
            }
            if bubbleVM === vm { then() }
        }
    }
}

// MARK: - Word card

struct WordCard: Identifiable, Equatable {
    /// Also the card's slot in the finished sentence
    let id: Int
    let text: String
    let isTarget: Bool
    /// Column the card starts in, above the tray
    var home: Int = 0

    /// "The *sock* is red." → The / sock (target) / is / red.
    static func parse(_ sentence: String) -> [WordCard] {
        sentence.split(separator: " ").enumerated().map { i, word in
            WordCard(id: i, text: word.replacingOccurrences(of: "*", with: ""), isTarget: word.contains("*"))
        }
    }
}

// MARK: - Layout

/// Landscape metrics: BEEMOO + bubble top-left, the word cards in a row, the wooden tray of slots
/// below them, progress / scoring / Next along the bottom. The picture takes the top-right corner.
struct SentenceBuilderLayout {
    let size: CGSize
    let wordCount: Int

    /// iPhone landscape (short screens)
    var isCompact: Bool { size.height < 600 }
    var margin: CGFloat { isCompact ? 10 : 24 }

    var beemooSize: CGFloat { min(max(size.height * 0.26, 84), 180) }
    /// BEEMOO starts right of the runner's 44pt home button (RunnerChrome)
    private var beemooLeft: CGFloat { isCompact ? 58 : 72 }
    var beemooCenter: CGPoint { CGPoint(x: beemooLeft + beemooSize / 2, y: margin + beemooSize / 2) }
    var bubbleLeft: CGFloat { beemooLeft + beemooSize + 2 }
    var speakerSize: CGFloat { isCompact ? 38 : 52 }

    /// Bubble text width, leaving room for the speaker and anything sitting top-right
    func bubbleWidth(beside obstacle: CGRect?) -> CGFloat {
        let right = (obstacle?.minX ?? size.width - margin) - 12
        return max(min(right - bubbleLeft - 10 - speakerSize - 10, 520), 160)
    }

    // Slots and cards
    var slotHeight: CGFloat { min(max(size.height * 0.14, 48), 104) }
    var slotGap: CGFloat { isCompact ? 8 : 14 }
    var trayPadding: CGFloat { slotHeight * 0.22 }
    var cardRadius: CGFloat { isCompact ? 12 : 18 }
    var trayRadius: CGFloat { isCompact ? 18 : 28 }
    var cardFontSize: CGFloat { slotHeight * 0.44 }

    var slotWidth: CGFloat {
        let n = CGFloat(wordCount)
        let maxTray = min(size.width - margin * 2, isCompact ? 780 : 1000)
        let fit = (maxTray - trayPadding * 2 - slotGap * (n - 1)) / n
        return min(fit, slotHeight * 2.4)
    }

    var trayRect: CGRect {
        let n = CGFloat(wordCount)
        let w = n * slotWidth + slotGap * (n - 1) + trayPadding * 2
        let h = slotHeight + trayPadding * 2
        let centerY = size.height * (isCompact ? 0.6 : 0.58)
        return CGRect(x: (size.width - w) / 2, y: centerY - h / 2, width: w, height: h)
    }

    func slotCenter(_ i: Int) -> CGPoint {
        CGPoint(
            x: trayRect.minX + trayPadding + slotWidth / 2 + CGFloat(i) * (slotWidth + slotGap),
            y: trayRect.midY
        )
    }

    /// Cards start in a row halfway between BEEMOO's row and the tray
    func homeCenter(_ column: Int) -> CGPoint {
        CGPoint(x: slotCenter(column).x, y: (margin + beemooSize + trayRect.minY) / 2 + (isCompact ? 2 : 6))
    }

    /// The slot a dropped card's center lands in (generous, so small fingers don't miss)
    func slot(at p: CGPoint) -> Int? {
        guard abs(p.y - trayRect.midY) <= slotHeight * 0.95 else { return nil }
        let i = Int(((p.x - trayRect.minX - trayPadding + slotGap / 2) / (slotWidth + slotGap)).rounded(.down))
        return (0..<wordCount).contains(i) ? i : nil
    }

    // Reward picture: top-right, above the tray, 3:2 like the sentence art
    var pictureRect: CGRect {
        let h = trayRect.minY - margin - (isCompact ? 8 : 16)
        let w = min(h * 1.5, size.width * 0.36)
        return CGRect(x: size.width - margin - w, y: margin, width: w, height: w / 1.5)
    }

    // Bottom bar
    var barHeight: CGFloat { min(max(size.height * 0.11, 44), 68) }
    var barCenterY: CGFloat { size.height - margin - barHeight / 2 }

    // Leaf-wipe hint card, top-right
    var hintRect: CGRect {
        let w = isCompact ? 170.0 : 250.0
        let h = isCompact ? 96.0 : 140.0
        return CGRect(x: size.width - margin - w, y: margin, width: w, height: h)
    }
}

// MARK: - Small pieces

extension Color {
    /// Target-word red in the finished sentence
    static let bmSentenceRed = Color(red: 222/255, green: 52/255, blue: 40/255)
}

private struct SparkleStar {
    let x: CGFloat, y: CGFloat, size: CGFloat
    /// Offsets as fractions of the picture's size, from its center
    static let around = [
        SparkleStar(x: -0.52, y: -0.42, size: 0.14),
        SparkleStar(x: 0.5, y: -0.46, size: 0.1),
        SparkleStar(x: -0.56, y: 0.36, size: 0.1),
        SparkleStar(x: 0.54, y: 0.4, size: 0.13),
    ]
}

/// A finger sweeping back and forth over a double arrow.
private struct SwipeHandHint: View {
    let size: CGFloat
    @State private var swing = false

    var body: some View {
        ZStack {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(Color.bmBlue)
                .offset(y: -size * 0.2)
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: size * 0.7))
                .foregroundStyle(.white)
                .shadow(color: Color.bmNavy.opacity(0.4), radius: 1)
                .offset(x: swing ? size * 0.35 : -size * 0.35, y: size * 0.15)
        }
        .frame(height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { swing = true }
        }
    }
}

// MARK: - Surprise animal

/// One jungle animal per finished set. Monkey, toucan and elephant are left out: other games use them.
struct SurpriseAnimal: Equatable {
    let id: String
    let name: String
    /// Placeholder art until the illustrated animals exist
    let emoji: String

    var article: String { "aeiou".contains(name.prefix(1)) ? "an" : "a" }

    static let pool = [
        SurpriseAnimal(id: "gorilla", name: "gorilla", emoji: "🦍"),
        SurpriseAnimal(id: "leopard", name: "leopard", emoji: "🐆"),
        SurpriseAnimal(id: "tree-frog", name: "tree frog", emoji: "🐸"),
        SurpriseAnimal(id: "iguana", name: "iguana", emoji: "🦎"),
        SurpriseAnimal(id: "sloth", name: "sloth", emoji: "🦥"),
        SurpriseAnimal(id: "macaw", name: "macaw", emoji: "🦜"),
        SurpriseAnimal(id: "butterfly", name: "blue morpho butterfly", emoji: "🦋"),
    ]

    private static let lastKey = "sentenceBuilder.lastSurpriseAnimal"

    /// Random, but never the same animal twice in a row
    static func next() -> SurpriseAnimal {
        let last = UserDefaults.standard.string(forKey: lastKey)
        let pick = pool.filter { $0.id != last }.randomElement() ?? pool[0]
        UserDefaults.standard.set(pick.id, forKey: lastKey)
        return pick
    }
}

// MARK: - Leaf wipe

/// The animal sits in a sunny clearing under a full cover of leaves. Swiping flicks the leaves
/// under the finger away; once most are gone, the rest blow off and the animal is revealed.
private struct LeafRevealView: View {
    let animal: SurpriseAnimal
    let onRevealed: () -> Void

    /// Full screen, safe areas included, so the leaves cover every edge
    @State private var size: CGSize = .zero
    @State private var leaves: [Leaf] = []
    @State private var revealed = false
    @State private var lastPoint: CGPoint?
    @State private var bob = false

    private struct Leaf {
        var center: CGPoint
        let length: CGFloat
        let angle: Double
        let color: Color
        var flyStart: Date?
        var flyDirection = CGVector(dx: 0, dy: -1)
    }

    private let flyDuration = 0.7
    /// Share of leaves that must be swiped before the rest blow away
    private let revealThreshold = 0.5

    private var spacing: CGFloat { min(size.width, size.height) * 0.12 }

    var body: some View {
        GeometryReader { geo in
            content
                .onAppear {
                    size = geo.size
                    if leaves.isEmpty { leaves = makeLeaves() }
                }
        }
        .ignoresSafeArea()
    }

    private var content: some View {
        ZStack {
            clearing
            TimelineView(.animation(paused: leaves.allSatisfy { $0.flyStart != nil && Date().timeIntervalSince($0.flyStart!) > flyDuration })) { timeline in
                Canvas { ctx, _ in
                    for leaf in leaves { draw(leaf, now: timeline.date, in: &ctx) }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { swipe(to: $0.location) }
                    .onEnded { _ in lastPoint = nil }
            )
            .allowsHitTesting(!revealed)
        }
    }

    private var clearing: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "FFF6C8"), Color(hex: "B8E07A"), Color(hex: "4E9A3A")],
                center: .center, startRadius: 0, endRadius: max(size.width, size.height) * 0.6
            )
            VStack(spacing: 4) {
                Text(animal.emoji)
                    .font(.system(size: min(size.width, size.height) * 0.42))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 6)
                    .offset(y: bob ? -8 : 8)
                    .scaleEffect(revealed ? 1.1 : 1)
                if revealed {
                    Text(animal.name.capitalized)
                        .font(.baloo2(size.height < 600 ? 26 : 40))
                        .foregroundStyle(Color.bmNavy)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.9)))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .offset(y: size.height * 0.06)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true }
        }
    }

    // Jittered grid of overlapping leaves, one step past every edge so the cover has no gaps
    private func makeLeaves() -> [Leaf] {
        let greens = ["2F7D32", "3E9B4F", "4CAF50", "5DBB4C", "2E6B30", "6CC24A", "37874A"].map { Color(hex: $0) }
        var out: [Leaf] = []
        let cols = Int(size.width / spacing) + 2
        let rows = Int(size.height / spacing) + 2
        for r in 0...rows {
            for c in 0...cols {
                let x = (CGFloat(c) - 0.5 + .random(in: -0.35...0.35)) * spacing
                let y = (CGFloat(r) - 0.5 + .random(in: -0.35...0.35)) * spacing
                out.append(Leaf(
                    center: CGPoint(x: x, y: y),
                    length: spacing * .random(in: 2.2...2.9),
                    angle: .random(in: 0...(2 * .pi)),
                    color: greens.randomElement()!
                ))
            }
        }
        return out.shuffled()
    }

    private func draw(_ leaf: Leaf, now: Date, in ctx: inout GraphicsContext) {
        var center = leaf.center
        var angle = leaf.angle
        var opacity = 1.0
        if let start = leaf.flyStart {
            // Leaves blown off at the end start a moment apart, so t can still be negative
            let t = max(now.timeIntervalSince(start), 0)
            guard t < flyDuration else { return }
            let distance = spacing * 9 * t
            center.x += leaf.flyDirection.dx * distance
            center.y += leaf.flyDirection.dy * distance + spacing * 6 * t * t
            angle += t * 6
            opacity = 1 - t / flyDuration
        }
        let l = leaf.length, w = leaf.length * 0.46
        var shape = Path()
        shape.move(to: CGPoint(x: -l / 2, y: 0))
        shape.addQuadCurve(to: CGPoint(x: l / 2, y: 0), control: CGPoint(x: 0, y: -w))
        shape.addQuadCurve(to: CGPoint(x: -l / 2, y: 0), control: CGPoint(x: 0, y: w))
        var rib = Path()
        rib.move(to: CGPoint(x: -l / 2, y: 0))
        rib.addLine(to: CGPoint(x: l * 0.42, y: 0))

        var c = ctx
        c.opacity = opacity
        c.translateBy(x: center.x, y: center.y)
        c.rotate(by: .radians(angle))
        c.fill(shape, with: .color(leaf.color))
        c.stroke(shape, with: .color(.black.opacity(0.18)), lineWidth: 1.5)
        c.stroke(rib, with: .color(.white.opacity(0.35)), lineWidth: max(l * 0.025, 1.5))
    }

    private func swipe(to point: CGPoint) {
        guard !revealed else { return }
        let previous = lastPoint ?? point
        lastPoint = point
        var direction = CGVector(dx: point.x - previous.x, dy: point.y - previous.y)
        let len = hypot(direction.dx, direction.dy)
        let now = Date()
        let radius = spacing * 1.3
        for i in leaves.indices where leaves[i].flyStart == nil {
            let d = hypot(leaves[i].center.x - point.x, leaves[i].center.y - point.y)
            guard d < radius else { continue }
            // Fling along the swipe, nudged away from the finger
            let away = CGVector(dx: (leaves[i].center.x - point.x) / max(d, 1), dy: (leaves[i].center.y - point.y) / max(d, 1))
            if len > 0.5 {
                direction = CGVector(dx: direction.dx / len, dy: direction.dy / len)
                leaves[i].flyDirection = CGVector(dx: direction.dx * 0.7 + away.dx * 0.3, dy: direction.dy * 0.7 + away.dy * 0.3)
            } else {
                leaves[i].flyDirection = away
            }
            leaves[i].flyStart = now
        }
        // Only leaves over the middle of the screen count, so nobody has to scrub the corners
        let inner = CGRect(origin: .zero, size: size).insetBy(dx: size.width * 0.15, dy: size.height * 0.15)
        let middle = leaves.filter { inner.contains($0.center) }
        let cleared = Double(middle.filter { $0.flyStart != nil }.count) / Double(max(middle.count, 1))
        if cleared >= revealThreshold { blowAway() }
    }

    private func blowAway() {
        revealed = true
        let mid = CGPoint(x: size.width / 2, y: size.height / 2)
        let now = Date()
        for i in leaves.indices where leaves[i].flyStart == nil {
            let dx = leaves[i].center.x - mid.x, dy = leaves[i].center.y - mid.y
            let d = max(hypot(dx, dy), 1)
            leaves[i].flyDirection = CGVector(dx: dx / d, dy: dy / d)
            leaves[i].flyStart = now.addingTimeInterval(.random(in: 0...0.25))
        }
        onRevealed()
    }
}
