import SwiftUI

/// Levels 3-5 — Word Production as a matching game.
/// Shows a grid of face-down cards (pairs of each word image).
/// Child flips two cards; if they match, the pair stays revealed,
/// the word model plays, BEEMOO says "Say the word", and the adult scores.
struct WordProductionScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @State private var cards: [MatchCard] = []
    @State private var flippedIndices: Set<Int> = []
    @State private var matchedIds: Set<String> = []
    @State private var firstFlip: Int?
    @State private var isChecking = false

    // Scoring state for a matched word
    @State private var scoringStimulus: StimulusConfig?
    @State private var isRetry = false
    @State private var trialId = UUID()

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    private var stimuli: [StimulusConfig] {
        screen.stimuli ?? []
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Card grid
                cardGrid(size: geo.size)

                // BEEMOO bubble
                if let vm = bubbleVM {
                    VStack {
                        HStack {
                            Spacer().frame(width: 70)
                            NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.35)
                            Spacer()
                        }
                        .padding(.top, 60)
                        Spacer()
                    }
                }

                // Scoring bar (appears when a match is found)
                if scoringStimulus != nil {
                    VStack {
                        Spacer()
                        AdultScoringBar(
                            onCorrect: { handleScore(.correct) },
                            onTryAgain: { handleScore(.tryAgain) },
                            onSkip: { handleScore(.skip) },
                            isRetry: isRetry
                        )
                        .padding(.bottom, 14)
                    }
                }

                // Progress
                VStack {
                    Spacer()
                    HStack {
                        progressDots
                            .padding(.leading, 20)
                            .padding(.bottom, 14)
                        Spacer()
                    }
                }
            }
        }
        .background { JungleBackground() }
        .onAppear { setupCards() }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Card grid

    private func cardGrid(size: CGSize) -> some View {
        let columns = 5
        let rows = 2
        let hPad: CGFloat = 80
        let vPad: CGFloat = 70
        let spacing: CGFloat = 8
        let availW = size.width - hPad * 2 - spacing * CGFloat(columns - 1)
        let availH = size.height - vPad * 2 - spacing * CGFloat(rows - 1)
        let cardW = availW / CGFloat(columns)
        let cardH = availH / CGFloat(rows)

        return VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let idx = row * columns + col
                        if idx < cards.count {
                            matchCardView(index: idx, width: cardW, height: cardH)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    private func matchCardView(index: Int, width: CGFloat, height: CGFloat) -> some View {
        let card = cards[index]
        let isFlipped = flippedIndices.contains(index) || matchedIds.contains(card.stimulusId)
        let isMatched = matchedIds.contains(card.stimulusId)

        return Button {
            guard !isChecking, !isMatched, !flippedIndices.contains(index), scoringStimulus == nil else { return }
            flipCard(at: index)
        } label: {
            ZStack {
                if isFlipped {
                    RemoteImage(filename: card.imageFilename)
                        .scaledToFit()
                        .padding(4)
                } else {
                    // Face-down card
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.bmBlue.opacity(0.15))
                        .overlay {
                            Image(systemName: "questionmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.bmBlue.opacity(0.4))
                        }
                }
            }
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMatched ? Color.bmConceptGreen : Color.bmNavy09, lineWidth: isMatched ? 3 : 1)
                    )
                    .bmCardShadow()
            )
            .opacity(isMatched && scoringStimulus?.stimulusId != card.stimulusId ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Card logic

    private func setupCards() {
        // Use first 5 stimuli for a 2x5 grid (10 cards = 5 pairs)
        let subset = Array(stimuli.prefix(5))
        var deck: [MatchCard] = []
        for s in subset {
            deck.append(MatchCard(stimulusId: s.stimulusId, imageFilename: s.wordImage))
            deck.append(MatchCard(stimulusId: s.stimulusId, imageFilename: s.wordImage))
        }
        cards = deck.shuffled()
    }

    private func flipCard(at index: Int) {
        withAnimation(.easeOut(duration: 0.2)) {
            flippedIndices.insert(index)
        }

        if let first = firstFlip {
            // Second card flipped
            isChecking = true
            let firstCard = cards[first]
            let secondCard = cards[index]

            if firstCard.stimulusId == secondCard.stimulusId {
                // Match found!
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    withAnimation(.spring(duration: 0.3)) {
                        matchedIds.insert(firstCard.stimulusId)
                    }
                    flippedIndices.remove(first)
                    flippedIndices.remove(index)
                    firstFlip = nil
                    isChecking = false

                    // Start scoring flow for this word
                    if let stimulus = stimuli.first(where: { $0.stimulusId == firstCard.stimulusId }) {
                        scoringStimulus = stimulus
                        trialId = UUID()
                        isRetry = false
                        speakWord(stimulus)
                    }
                }
            } else {
                // No match — flip back
                Task {
                    try? await Task.sleep(for: .milliseconds(800))
                    withAnimation(.easeOut(duration: 0.25)) {
                        flippedIndices.remove(first)
                        flippedIndices.remove(index)
                    }
                    firstFlip = nil
                    isChecking = false
                }
            }
        } else {
            firstFlip = index
        }
    }

    // MARK: - Audio + narration

    private func speakWord(_ stimulus: StimulusConfig) {
        // Play the word, then show "Say the word" bubble
        let wordTrack = SystemNarrationTrack()
        wordTrack.speak(stimulus.targetWord, onWord: { _ in }, onFinish: { [self] in
            let text = "Say the word."
            let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
            vm.isNarrationOff = !settings.narrationEnabled
            self.bubbleVM = vm
            vm.startNarration()
        })
    }

    // MARK: - Progress

    private var progressDots: some View {
        let total = min(stimuli.count, 5)
        return HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                let sid = stimuli[i].stimulusId
                Circle()
                    .fill(matchedIds.contains(sid) ? Color.bmConceptGreen : Color.bmNavy09)
                    .frame(width: 9, height: 9)
            }
        }
    }

    // MARK: - Scoring

    private enum ScoreAction { case correct, tryAgain, skip }

    private func handleScore(_ action: ScoreAction) {
        guard let stimulus = scoringStimulus else { return }

        switch action {
        case .correct:
            logTrial(stimulus: stimulus, outcome: isRetry ? "incorrect" : "correct",
                     retryOutcome: isRetry ? "correct" : nil)
            finishScoring()

        case .tryAgain:
            isRetry = true

        case .skip:
            logTrial(stimulus: stimulus, outcome: isRetry ? "incorrect" : "skip",
                     retryOutcome: isRetry ? "skip" : nil)
            finishScoring()
        }
    }

    private func logTrial(stimulus: StimulusConfig, outcome: String, retryOutcome: String?) {
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
            firstAttemptOutcome: outcome,
            retryPrompted: isRetry,
            retryOutcome: retryOutcome
        )
        trialLogger.log(record)
    }

    private func finishScoring() {
        scoringStimulus = nil
        bubbleVM = nil
        isRetry = false

        // Check if all pairs found
        let total = min(stimuli.count, 5)
        if matchedIds.count >= total {
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                onAdvance()
            }
        }
    }
}

// MARK: - Match card model

private struct MatchCard: Identifiable {
    let id = UUID()
    let stimulusId: String
    let imageFilename: String
}
