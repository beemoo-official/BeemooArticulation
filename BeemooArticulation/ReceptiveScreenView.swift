import SwiftUI

struct ReceptiveScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @State private var shuffledChoices: [ChoiceConfig] = []
    @State private var attempts: Int = 0
    @State private var firstTry: Bool = true
    @State private var selectedMeaning: String?
    @State private var isCorrect: Bool?
    @State private var choicesEnabled: Bool = true
    @State private var showCorrectFeedback: Bool = false
    @State private var trialId = UUID()

    var body: some View {
        VStack(spacing: 0) {
            // Choice panels fill space above the prompt plate
            choicePanels

            // Prompt plate pinned to bottom
            if let text = screen.displayText {
                PromptPlate(text: text)
            }
        }
        .background(Color.bmCream)
        .onAppear { shuffleAndReset() }
    }

    // MARK: - Choice panels

    private var choicePanels: some View {
        GeometryReader { geo in
            HStack(spacing: 16) {
                ForEach(shuffledChoices) { choice in
                    choiceCard(choice, height: geo.size.height)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func choiceCard(_ choice: ChoiceConfig, height: CGFloat) -> some View {
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
            Image(choice.assetName)
                .resizable()
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
        }
        .buttonStyle(.plain)
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

            // Log trial
            let record = TrialRecord(
                id: trialId,
                screenId: screen.n,
                activityId: activityId,
                concept: screen.concept,
                firstTry: firstTry,
                attempts: attempts,
                timestamp: Date()
            )
            trialLogger.log(record)

            // Advance after feedback
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                onAdvance()
            }
        } else {
            // Wrong answer
            if firstTry { firstTry = false }

            switch settings.wrongAnswerResponse {
            case .retrySameScreen:
                // Brief feedback, then re-enable choices
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    selectedMeaning = nil
                    isCorrect = nil
                }

            case .advanceAnyway:
                let record = TrialRecord(
                    id: trialId,
                    screenId: screen.n,
                    activityId: activityId,
                    concept: screen.concept,
                    firstTry: false,
                    attempts: attempts,
                    timestamp: Date()
                )
                trialLogger.log(record)
                choicesEnabled = false
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    onAdvance()
                }

            case .reTeachThenRetry:
                // For now, behave like retry (re-teach requires runner-level navigation)
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    selectedMeaning = nil
                    isCorrect = nil
                }
            }
        }
    }

    private func shuffleAndReset() {
        let source = screen.choices ?? []
        shuffledChoices = (screen.shuffleChoices == true) ? source.shuffled() : source
        attempts = 0
        firstTry = true
        selectedMeaning = nil
        isCorrect = nil
        choicesEnabled = true
        showCorrectFeedback = false
        trialId = UUID()
    }
}
