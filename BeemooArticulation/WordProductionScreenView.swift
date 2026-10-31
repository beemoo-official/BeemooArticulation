import SwiftUI

/// Levels 3-5 — Word Production (Beginning / Final / Middle S Words).
/// Iterates through stimuli, showing each word image enlarged with audio
/// and adult scoring (Correct / Try Again / Skip).
struct WordProductionScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @State private var currentIndex = 0
    @State private var isRetry = false
    @State private var trialId = UUID()
    @State private var showImage = true

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    private var stimuli: [StimulusConfig] {
        screen.stimuli ?? []
    }

    private var current: StimulusConfig? {
        guard currentIndex < stimuli.count else { return nil }
        return stimuli[currentIndex]
    }

    var body: some View {
        GeometryReader { geo in
            if let stimulus = current {
                ZStack {
                    // Word image centered
                    wordCard(stimulus, size: geo.size)

                    // BEEMOO bubble top-leading
                    VStack {
                        HStack {
                            Spacer().frame(width: 70)
                            if let vm = bubbleVM {
                                NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.4)
                            }
                            Spacer()
                        }
                        .padding(.top, 60)
                        Spacer()
                    }

                    // Word label + speaker
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Spacer()
                            Text(stimulus.targetWord.capitalized)
                                .font(.baloo2(28))
                                .foregroundStyle(Color.bmNavy)
                            SpeakerButton(
                                text: stimulus.audioText ?? stimulus.targetWord,
                                size: 40
                            )
                            Spacer()
                        }
                        .padding(.bottom, 4)

                        // Adult scoring bar
                        AdultScoringBar(
                            onCorrect: { handleScore(.correct) },
                            onTryAgain: { handleScore(.tryAgain) },
                            onSkip: { handleScore(.skip) },
                            isRetry: isRetry
                        )
                        .padding(.bottom, 16)
                    }

                    // Progress counter
                    VStack {
                        Spacer()
                        HStack {
                            progressDots
                                .padding(.leading, 20)
                                .padding(.bottom, 16)
                            Spacer()
                        }
                    }
                }
            }
        }
        .background(Color.bmCream)
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Word card

    private func wordCard(_ stimulus: StimulusConfig, size: CGSize) -> some View {
        RemoteImage(filename: stimulus.wordImage)
            .scaledToFit()
            .frame(maxWidth: size.width * 0.4, maxHeight: size.height * 0.55)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: BM.cardRadius)
                    .fill(.white)
                    .bmCardShadow()
            )
            .opacity(showImage ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: showImage)
    }

    // MARK: - Progress

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(0..<stimuli.count, id: \.self) { i in
                Circle()
                    .fill(i < currentIndex ? Color.bmConceptGreen
                          : i == currentIndex ? Color.bmYellow
                          : Color.bmNavy09)
                    .frame(width: 9, height: 9)
            }
        }
    }

    // MARK: - Scoring

    private enum ScoreAction { case correct, tryAgain, skip }

    private func handleScore(_ action: ScoreAction) {
        guard let stimulus = current else { return }

        switch action {
        case .correct:
            let record = TrialRecord(
                id: trialId,
                screenId: screen.n,
                activityId: activityId,
                concept: screen.concept,
                firstTry: !isRetry,
                attempts: isRetry ? 2 : 1,
                timestamp: Date(),
                stimulusId: stimulus.stimulusId,
                targetWord: stimulus.targetWord,
                targetPosition: stimulus.targetPosition,
                stimulusType: "word",
                firstAttemptOutcome: isRetry ? "incorrect" : "correct",
                retryPrompted: isRetry,
                retryOutcome: isRetry ? "correct" : nil
            )
            trialLogger.log(record)
            advanceStimulus()

        case .tryAgain:
            isRetry = true

        case .skip:
            let record = TrialRecord(
                id: trialId,
                screenId: screen.n,
                activityId: activityId,
                concept: screen.concept,
                firstTry: !isRetry,
                attempts: isRetry ? 2 : 1,
                timestamp: Date(),
                stimulusId: stimulus.stimulusId,
                targetWord: stimulus.targetWord,
                targetPosition: stimulus.targetPosition,
                stimulusType: "word",
                firstAttemptOutcome: isRetry ? "incorrect" : "skip",
                retryPrompted: isRetry,
                retryOutcome: isRetry ? "skip" : nil
            )
            trialLogger.log(record)
            advanceStimulus()
        }
    }

    private func advanceStimulus() {
        let next = currentIndex + 1
        if next >= stimuli.count {
            onAdvance()
        } else {
            withAnimation(.easeOut(duration: 0.2)) { showImage = false }
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                currentIndex = next
                isRetry = false
                trialId = UUID()
                withAnimation(.easeOut(duration: 0.25)) { showImage = true }
                startNarration()
            }
        }
    }

    // MARK: - Narration

    private func startNarration() {
        let text = screen.displayText ?? "Say the word."
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }
}
