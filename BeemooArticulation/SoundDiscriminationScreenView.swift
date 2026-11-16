import SwiftUI

/// Level 2 — Hear the S Sound.
/// Intro: BEEMOO centered, "Let's listen for the S sound!", Continue button below.
/// Game: BEEMOO top-left, 3 image cards with speaker buttons, child picks the /s/ word.
struct SoundDiscriminationScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void
    let isFirstScreen: Bool

    @Environment(APIClient.self) private var apiClient

    @State private var phase: Phase = .game
    @State private var shuffledChoices: [ChoiceConfig] = []
    @State private var attempts = 0
    @State private var firstTry = true
    @State private var selectedMeaning: String?
    @State private var isCorrect: Bool?
    @State private var choicesEnabled = false
    @State private var showCorrectFeedback = false
    @State private var showContinueButton = false
    @State private var correctRevealed = false   // wrong cards faded, correct centered
    @State private var trialId = UUID()
    @State private var showActionButton = false
    @State private var highlightedIndex: Int? = nil
    @State private var dismissing = false

    @State private var bubbleVM: NarratedBubbleVM?
    /// BEEMOO's voice: pre-recorded clips (voice/beemoo/…), falling back to the system voice. Set on appear.
    @State private var narrationTrack: any NarrationTrack = SystemNarrationTrack()
    @State private var speakerTrack: any NarrationTrack = SystemNarrationTrack()  // persistent track for speaker buttons
    @State private var sfxPlayer = RemoteAudioPlayer()

    enum Phase {
        case intro
        case game
    }

    private var beemooCentered: Bool { phase == .intro }

    var body: some View {
        GeometryReader { geo in
            let layout = GameSceneLayout(size: geo.size)
            ZStack {
                // BEEMOO mascot
                beemooMascot(layout)

                // Speech bubble — above the big BEEMOO (intro) or beside the small one (game)
                if let vm = bubbleVM {
                    BeemooSpeechBubble(vm: vm, layout: layout, heroPose: beemooCentered)
                        .opacity(dismissing ? 0 : 1)
                }

                // Intro action button
                if phase == .intro && showActionButton {
                    introButton(layout)
                        .transition(.scale.combined(with: .opacity))
                }

                // Game content
                if phase == .game {
                    choicePanels(layout)
                        .opacity(dismissing ? 0 : 1)
                        .scaleEffect(dismissing ? 0.9 : 1.0)
                        .transition(.opacity)

                    // Continue button after correct answer
                    if showContinueButton && !dismissing {
                        continueButton(layout)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
            narrationTrack = VoiceClipNarrationTrack(apiClient: apiClient)
            speakerTrack = VoiceClipNarrationTrack(apiClient: apiClient)
            shuffleAndReset()
            if isFirstScreen {
                phase = .intro
                startIntroNarration()
            } else {
                phase = .game
                startGameNarration()
            }
        }
        .onDisappear {
            narrationTrack.stop()
            speakerTrack.stop()
        }
    }

    // MARK: - BEEMOO mascot

    private func beemooMascot(_ layout: GameSceneLayout) -> some View {
        RemoteImage(filename: "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? layout.heroSize.width : layout.beemooSize,
                height: beemooCentered ? layout.heroSize.height : layout.beemooSize
            )
            .position(beemooCentered ? layout.heroCenter : layout.beemooCenter)
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Buttons

    private func introButton(_ layout: GameSceneLayout) -> some View {
        Button {
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                phase = .game
                showActionButton = false
                bubbleVM = nil
            }
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                startGameNarration()
            }
        } label: {
            Text("Continue")
                .font(.baloo2(24))
                .foregroundStyle(.white)
                .frame(width: 160, height: 52)
                .background(Capsule().fill(Color.bmConceptGreen))
                .bmRaisedShadow()
        }
        .buttonStyle(.plain)
        .position(x: layout.size.width / 2, y: layout.actionY)
    }

    private func continueButton(_ layout: GameSceneLayout) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                dismissing = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                onAdvance()
            }
        } label: {
            HStack(spacing: 6) {
                Text("Continue")
                    .font(.baloo2(20))
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.bmConceptGreen))
            .bmRaisedShadow()
        }
        .buttonStyle(.plain)
        // Bottom-right corner, clear of the centered winning card
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(layout.margin + (layout.isCompact ? 4 : 8))
    }

    // MARK: - Choice panels

    /// Card size: as big as the game area allows, with the speaker button's overhang below,
    /// never wider than 1 : 1.2 tall-to-wide (keeps the picture the hero, not white space).
    private func cardSize(_ layout: GameSceneLayout) -> CGSize {
        let area = layout.gameRect
        let sideInset: CGFloat = layout.isCompact ? 40 : area.width * 0.08
        let maxW = (area.width - 2 * sideInset - 2 * cardSpacing(layout)) / 3
        let maxH = area.height - speakerSize(layout) / 2 - (layout.isCompact ? 4 : 12)
        let h = min(maxH, maxW / 0.8)
        return CGSize(width: min(maxW, h * 1.2), height: h)
    }

    private func cardSpacing(_ layout: GameSceneLayout) -> CGFloat { layout.isCompact ? 18 : 28 }
    private func speakerSize(_ layout: GameSceneLayout) -> CGFloat { layout.isCompact ? 46 : 60 }

    private func choicePanels(_ layout: GameSceneLayout) -> some View {
        let card = cardSize(layout)
        let spacing = cardSpacing(layout)
        let area = layout.gameRect
        // The row of cards (plus the speaker overhang) is centered in the game area
        let rowCenterY = area.midY - speakerSize(layout) / 4
        // When revealed, the winner grows; keep it inside the game area
        let revealScale = min(1.15, (area.height - speakerSize(layout) / 2) / card.height)

        return HStack(spacing: spacing) {
            ForEach(Array(shuffledChoices.enumerated()), id: \.element.id) { index, choice in
                let isRight = choice.meaning == screen.correct
                let isWrong = !isRight

                let cardSlot = card.width + spacing
                let xOffset: CGFloat = correctRevealed && isRight ? CGFloat(1 - index) * cardSlot : 0

                choiceCard(choice, index: index, width: card.width, height: card.height, speaker: speakerSize(layout))
                    .scaleEffect(correctRevealed && isRight ? revealScale : 1.0)
                    .offset(x: xOffset)
                    .opacity(correctRevealed && isWrong ? 0 : 1)
                    .zIndex(correctRevealed && isRight ? 10 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.2), value: correctRevealed)
            }
        }
        .position(x: layout.size.width / 2, y: rowCenterY)
    }

    private func choiceCard(_ choice: ChoiceConfig, index: Int, width: CGFloat, height: CGFloat, speaker: CGFloat) -> some View {
        let isSelected = selectedMeaning == choice.meaning
        let isRight = choice.meaning == screen.correct
        let isHighlighted = highlightedIndex == index

        let feedbackBorder: Color? = {
            guard let correct = isCorrect, isSelected else { return nil }
            return correct ? Color.bmConceptGreen : Color.bmOrange
        }()

        return ZStack {
            // Card (tappable only when choices enabled)
            ZStack {
                ZStack {
                    Color.white
                    RemoteImage(filename: choice.asset)
                        .scaledToFit()
                        // Bottom padding leaves room for the speaker button's top half
                        .padding(.horizontal, width * 0.08)
                        .padding(.top, height * 0.07)
                        .padding(.bottom, speaker / 2 + height * 0.03)
                }
                .drawingGroup()
                .clipShape(RoundedRectangle(cornerRadius: 20))

                CardFrame()
            }
            .frame(width: width, height: height)
            .overlay(
                Group {
                    if let color = feedbackBorder {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color, lineWidth: 5)
                    }
                }
            )
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture {
                guard choicesEnabled else { return }
                handleChoice(choice)
            }

            // Speaker button — always tappable, independent of choicesEnabled
            .overlay(alignment: .bottom) {
                Button {
                    speakerTrack.speak(choice.meaning, onWord: { _ in }, onFinish: {})
                } label: {
                    RemoteImage(filename: "ui/speaker_button.png")
                        .scaledToFit()
                        .frame(width: speaker, height: speaker)
                }
                .buttonStyle(PressButtonStyle())
                .offset(y: speaker / 2)
                .opacity(correctRevealed && choice.meaning != screen.correct ? 0 : 1)
            }
            .shadow(
                color: isHighlighted ? Color.bmYellow.opacity(0.5) : .clear,
                radius: isHighlighted ? 12 : 0
            )
            .scaleEffect(isHighlighted ? 1.05 : (showCorrectFeedback && isRight ? 1.06 : 1.0))
            .animation(.spring(duration: 0.3), value: isHighlighted)
            .animation(.spring(duration: 0.32), value: showCorrectFeedback)
        }
    }

    // MARK: - Narration

    private func startIntroNarration() {
        let text = "Let's listen for the *S* sound!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()

        Task {
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.35)) {
                showActionButton = true
            }
        }
    }

    private func startGameNarration() {
        guard settings.narrationEnabled else {
            let text = screen.displayText ?? "Which one has the *S* sound?"
            let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
            vm.isNarrationOff = true
            self.bubbleVM = vm
            choicesEnabled = true
            return
        }

        // Just narrate the question word-by-word in the bubble
        Task {
            let question = screen.displayText ?? "Which one has the *S* sound?"
            let vm = NarratedBubbleVM(markerText: question, narrationTrack: narrationTrack)
            vm.isNarrationOff = false
            self.bubbleVM = vm
            vm.startNarration()

            while !(self.bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            choicesEnabled = true
        }
    }

    private func startCorrectNarration(word: String) {
        let text = "That's right! *\(word.capitalized)*!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()

        Task {
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.35)) {
                showContinueButton = true
            }
        }
    }

    // MARK: - Trial logic

    private func handleChoice(_ choice: ChoiceConfig) {
        selectedMeaning = choice.meaning
        attempts += 1

        let correct = choice.meaning == screen.correct
        isCorrect = correct

        if correct {
            choicesEnabled = false
            showCorrectFeedback = true
            sfxPlayer.play("sfx/correct.mp3", from: apiClient)

            let record = TrialRecord(
                id: trialId,
                screenId: screen.n,
                activityId: activityId,
                concept: screen.concept,
                firstTry: firstTry,
                attempts: attempts,
                timestamp: Date(),
                firstAttemptOutcome: firstTry ? "correct" : nil
            )
            trialLogger.log(record)

            // Animate: fade wrong cards, scale correct card, then narrate
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                    correctRevealed = true
                }
                try? await Task.sleep(for: .milliseconds(600))
                startCorrectNarration(word: choice.meaning)
            }
        } else {
            if firstTry { firstTry = false }
            sfxPlayer.play("sfx/incorrect.mp3", from: apiClient)

            Task {
                try? await Task.sleep(for: .milliseconds(600))
                selectedMeaning = nil
                isCorrect = nil
            }
        }
    }

    private func shuffleAndReset() {
        let source = screen.choices ?? []
        shuffledChoices = source.shuffled()
        attempts = 0
        firstTry = true
        selectedMeaning = nil
        isCorrect = nil
        choicesEnabled = false
        showCorrectFeedback = false
        showContinueButton = false
        correctRevealed = false
        trialId = UUID()
        highlightedIndex = nil
    }
}

/// Button style that never changes opacity on press or disabled state.
private struct NoFadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

/// Button style that scales down slightly on press, no opacity change.
private struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}
