import SwiftUI

/// Level 2 — Hear the S Sound.
/// Plays spoken words and asks which one contains /s/.
/// Child picks the picture; green/orange feedback like ReceptiveScreenView.
struct SoundDiscriminationScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @State private var shuffledChoices: [ChoiceConfig] = []
    @State private var attempts = 0
    @State private var firstTry = true
    @State private var selectedMeaning: String?
    @State private var isCorrect: Bool?
    @State private var choicesEnabled = false
    @State private var showCorrectFeedback = false
    @State private var trialId = UUID()

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                choicePanels(in: geo.size)

                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.55)
                        .padding(.top, 60)
                        .padding(.leading, 70)
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
            shuffleAndReset()
            startNarration()
        }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Choice panels

    private func choicePanels(in size: CGSize) -> some View {
        HStack(spacing: 16) {
            ForEach(shuffledChoices) { choice in
                choiceCard(choice)
            }
        }
        .padding(.leading, 70)
        .padding(.trailing, 80)
        .padding(.top, 12)
        .padding(.bottom, 60)
    }

    private func choiceCard(_ choice: ChoiceConfig) -> some View {
        let isSelected = selectedMeaning == choice.meaning
        let isRight = choice.meaning == screen.correct
        let borderColor: Color = {
            guard let correct = isCorrect, isSelected else { return .clear }
            return correct ? Color.bmConceptGreen : Color.bmOrange
        }()

        return Button {
            guard choicesEnabled else { return }
            handleChoice(choice)
        } label: {
            RemoteImage(filename: choice.asset)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: BM.cardRadius)
                        .fill(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BM.cardRadius)
                        .stroke(borderColor, lineWidth: isSelected ? 4 : 0)
                )
                .scaleEffect(showCorrectFeedback && isRight ? 1.06 : 1.0)
                .animation(.spring(duration: 0.32), value: showCorrectFeedback)
                .opacity(choicesEnabled ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!choicesEnabled)
    }

    // MARK: - Narration

    /// Narrates each choice word aloud, then asks the question, then enables taps.
    private func startNarration() {
        if !settings.narrationEnabled {
            let text = screen.displayText ?? "Which one has the *ssss* sound?"
            let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
            vm.isNarrationOff = true
            self.bubbleVM = vm
            choicesEnabled = true
            return
        }

        // Build a sentence like "Sun… cat… dog. Which one has the ssss sound?"
        let choiceWords = shuffledChoices.map { $0.meaning.capitalized }
        let listing = choiceWords.joined(separator: "… ")
        let question = screen.displayText ?? "Which one has the *ssss* sound?"
        let fullNarration = "\(listing). \(question)"

        let vm = NarratedBubbleVM(markerText: question, narrationTrack: narrationTrack)
        vm.isNarrationOff = false
        self.bubbleVM = vm

        // Speak the full narration (choice words + question)
        let strippedQuestion = StrippedText(from: question).stripped
        let fullText = "\(listing). \(strippedQuestion)"
        narrationTrack.speak(fullText, onWord: { _ in }, onFinish: { [weak vm] in
            // Reveal the full bubble text and enable choices
            vm?.revealAll()
            choicesEnabled = true
        })
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

            Task {
                try? await Task.sleep(for: .milliseconds(800))
                onAdvance()
            }
        } else {
            if firstTry { firstTry = false }

            // Always retry on wrong answer for discrimination
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
        trialId = UUID()
    }
}
