import SwiftUI

/// Levels 6-8 — Sentence Production (Beginning / Final / Middle S Sentences).
/// Large illustration + sentence text strip + speaker + adult scoring.
struct SentenceProductionScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @State private var currentIndex = 0
    @State private var isRetry = false
    @State private var trialId = UUID()
    @State private var showContent = true

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
                    VStack(spacing: 0) {
                        // Large illustration
                        illustrationArea(stimulus, size: geo.size)

                        // Sentence strip
                        sentenceStrip(stimulus, width: geo.size.width)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.25), value: showContent)

                    // BEEMOO bubble (small, bottom-leading)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer().frame(width: 70)
                            if let vm = bubbleVM {
                                NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.32)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 100)
                    }

                    // Adult scoring bar
                    VStack {
                        Spacer()
                        AdultScoringBar(
                            onCorrect: { handleScore(.correct) },
                            onTryAgain: { handleScore(.tryAgain) },
                            onSkip: { handleScore(.skip) },
                            isRetry: isRetry
                        )
                        .padding(.bottom, 8)
                    }

                    // Progress dots
                    VStack {
                        Spacer()
                        HStack {
                            progressDots
                                .padding(.leading, 20)
                                .padding(.bottom, 8)
                            Spacer()
                        }
                    }
                }
            }
        }
        .background { JungleBackground() }
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Illustration

    private func illustrationArea(_ stimulus: StimulusConfig, size: CGSize) -> some View {
        Group {
            if let sentenceImage = stimulus.sentenceImage {
                RemoteImage(filename: sentenceImage)
                    .scaledToFit()
                    .frame(maxWidth: size.width * 0.85, maxHeight: size.height * 0.55)
                    .clipShape(RoundedRectangle(cornerRadius: BM.cardRadius))
            } else {
                RemoteImage(filename: stimulus.wordImage)
                    .scaledToFit()
                    .frame(maxWidth: size.width * 0.6, maxHeight: size.height * 0.55)
                    .clipShape(RoundedRectangle(cornerRadius: BM.cardRadius))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 54)
    }

    // MARK: - Sentence strip

    private func sentenceStrip(_ stimulus: StimulusConfig, width: CGFloat) -> some View {
        HStack(spacing: 12) {
            SpeakerButton(
                text: stimulus.sentenceText ?? stimulus.targetWord,
                size: 44
            )

            if let sentence = stimulus.sentenceText {
                Text(MarkerParser.parse(sentence))
                    .font(.nunito(20, weight: .bold))
                    .foregroundStyle(Color.bmNavy)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.bmCream)
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
                stimulusType: "sentence",
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
                stimulusType: "sentence",
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
            withAnimation(.easeOut(duration: 0.2)) { showContent = false }
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                currentIndex = next
                isRetry = false
                trialId = UUID()
                withAnimation(.easeOut(duration: 0.25)) { showContent = true }
                startNarration()
            }
        }
    }

    // MARK: - Narration

    private func startNarration() {
        let text = screen.displayText ?? "Say the sentence."
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }
}
