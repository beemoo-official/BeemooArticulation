import SwiftUI

/// Level 2 — Hear the S Sound.
/// Intro: BEEMOO centered, "Let's listen for the ssssss sound!", Continue button.
/// Game: BEEMOO top-right, 3 image cards with speaker buttons, child picks the /s/ word.
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
    @State private var trialId = UUID()
    @State private var showActionButton = false
    @State private var highlightedIndex: Int? = nil  // which card is being named

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var listingTrack = SystemNarrationTrack()

    enum Phase {
        case intro
        case game
    }

    private var beemooCentered: Bool { phase == .intro }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // BEEMOO mascot
                beemooMascot(size: geo.size)

                // Speech bubble
                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * (beemooCentered ? 0.5 : 0.3))
                        .position(
                            x: beemooCentered ? geo.size.width * 0.5 : geo.size.width * 0.70,
                            y: beemooCentered ? geo.size.height * 0.28 : geo.size.height * 0.12
                        )
                }

                // Intro action button
                if phase == .intro && showActionButton {
                    introButton(size: geo.size)
                        .transition(.scale.combined(with: .opacity))
                }

                // Game content
                if phase == .game {
                    choicePanels(in: geo.size)
                        .transition(.opacity)

                    // Continue button after correct answer
                    if showContinueButton {
                        continueButton(size: geo.size)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
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
            listingTrack.stop()
        }
    }

    // MARK: - BEEMOO mascot

    private func beemooMascot(size: CGSize) -> some View {
        RemoteImage(filename: "BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? size.width * 0.28 : size.width * 0.1,
                height: beemooCentered ? size.height * 0.55 : size.height * 0.25
            )
            .position(
                x: beemooCentered ? size.width * 0.5 : size.width * 0.88,
                y: beemooCentered ? size.height * 0.62 : size.height * 0.15
            )
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Buttons

    private func introButton(size: CGSize) -> some View {
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
        .position(x: size.width * 0.5, y: size.height * 0.88)
    }

    private func continueButton(size: CGSize) -> some View {
        Button {
            onAdvance()
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
        .position(x: size.width * 0.88, y: size.height * 0.92)
    }

    // MARK: - Choice panels

    private func choicePanels(in size: CGSize) -> some View {
        let cardWidth = (size.width - 160 - 32) / 3
        let cardHeight = size.height * 0.55

        return HStack(spacing: 16) {
            ForEach(Array(shuffledChoices.enumerated()), id: \.element.id) { index, choice in
                choiceCard(choice, index: index, width: cardWidth, height: cardHeight)
            }
        }
        .padding(.horizontal, 80)
        .position(x: size.width * 0.5, y: size.height * 0.55)
    }

    private func choiceCard(_ choice: ChoiceConfig, index: Int, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selectedMeaning == choice.meaning
        let isRight = choice.meaning == screen.correct
        let isHighlighted = highlightedIndex == index

        let borderColor: Color = {
            if let correct = isCorrect, isSelected {
                return correct ? Color.bmConceptGreen : Color.bmOrange
            }
            if isHighlighted { return Color.bmYellow }
            return Color(hex: "8B5E3C")
        }()
        let borderWidth: CGFloat = (isSelected || isHighlighted) ? 5 : 3

        return VStack(spacing: 10) {
            Button {
                guard choicesEnabled else { return }
                handleChoice(choice)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                    RemoteImage(filename: choice.asset)
                        .scaledToFit()
                        .padding(12)
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .drawingGroup()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .shadow(
                        color: isHighlighted ? Color.bmYellow.opacity(0.5) : .clear,
                        radius: isHighlighted ? 12 : 0
                    )
                    .scaleEffect(isHighlighted ? 1.05 : (showCorrectFeedback && isRight ? 1.06 : 1.0))
                    .animation(.spring(duration: 0.3), value: isHighlighted)
                    .animation(.spring(duration: 0.32), value: showCorrectFeedback)
            }
            .buttonStyle(NoFadeButtonStyle())
            .allowsHitTesting(choicesEnabled)

            SpeakerButton(text: choice.meaning, size: 42)
        }
    }

    // MARK: - Narration

    private func startIntroNarration() {
        let text = "Let's listen for the *ssssss* sound!"
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
            let text = screen.displayText ?? "Which one has the *ssss* sound?"
            let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
            vm.isNarrationOff = true
            self.bubbleVM = vm
            choicesEnabled = true
            return
        }

        // Speak each choice word one at a time, highlighting the card
        Task {
            for i in 0..<shuffledChoices.count {
                let word = shuffledChoices[i].meaning.capitalized

                // Highlight this card
                withAnimation(.spring(duration: 0.2)) {
                    highlightedIndex = i
                }

                // Speak the word and wait for it to finish
                await withCheckedContinuation { cont in
                    listingTrack.speak(word, onWord: { _ in }, onFinish: {
                        cont.resume()
                    })
                }

                // Brief pause between words
                try? await Task.sleep(for: .milliseconds(400))

                // Un-highlight
                withAnimation(.spring(duration: 0.2)) {
                    highlightedIndex = nil
                }

                try? await Task.sleep(for: .milliseconds(200))
            }

            // Now narrate the question word-by-word in the bubble
            let question = screen.displayText ?? "Which one has the *ssss* sound?"
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

    // MARK: - Trial logic

    private func handleChoice(_ choice: ChoiceConfig) {
        selectedMeaning = choice.meaning
        attempts += 1

        let correct = choice.meaning == screen.correct
        isCorrect = correct

        if correct {
            choicesEnabled = false
            showCorrectFeedback = true

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

            // Show continue button instead of auto-advancing
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation(.spring(duration: 0.35)) {
                    showContinueButton = true
                }
            }
        } else {
            if firstTry { firstTry = false }

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
