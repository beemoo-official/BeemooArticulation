import SwiftUI
import AVFoundation
import Speech

// MARK: - Speech Recognizer

@Observable
final class WordRecognizer {
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var onResult: ((String) -> Void)?
    var isListening = false

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func startListening(onWordRecognized: @escaping (String) -> Void) {
        guard !isListening else { return }
        onResult = onWordRecognized

        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.main.async { self.beginRecognition() }
        }
    }

    private func beginRecognition() {
        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)

            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard format.channelCount > 0, format.sampleRate > 0 else { return }

            guard let safeFormat = AVAudioFormat(standardFormatWithSampleRate: format.sampleRate, channels: 1)
            else { return }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: safeFormat) { buffer, _ in
                request.append(buffer)
            }

            try engine.start()
            self.audioEngine = engine
            isListening = true

            recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let spoken = result.bestTranscription.formattedString.lowercased()
                    DispatchQueue.main.async {
                        self.onResult?(spoken)
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    DispatchQueue.main.async { self.stop() }
                }
            }

            // Auto-stop after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.stop()
            }
        } catch {
            isListening = false
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isListening = false
    }
}

// MARK: - Monkey Climb Screen

struct MonkeyClimbScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @Environment(APIClient.self) private var apiClient

    @State private var phase: Phase = .intro
    @State private var currentStimulusIndex = 0
    @State private var currentStep = 0
    @State private var trialId = UUID()
    @State private var showActionButton = false
    @State private var wordRecognizer = WordRecognizer()
    @State private var recognizedText = ""

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var sfxPlayer = RemoteAudioPlayer()

    private var config: MonkeyClimbConfig? { screen.monkeyClimb }
    private var stimuli: [StimulusConfig] { screen.stimuli ?? [] }
    private var currentStimulus: StimulusConfig? {
        guard currentStimulusIndex < stimuli.count else { return nil }
        return stimuli[currentStimulusIndex]
    }
    private var totalSteps: Int { config?.steps.count ?? 1 }

    enum Phase { case intro, climbing, complete }
    private var beemooCentered: Bool { phase == .intro }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tree on the right
                treeView(size: geo.size)

                // Monkey at current step
                monkeyView(size: geo.size)

                // BEEMOO mascot
                beemooMascot(size: geo.size)

                // Speech bubble
                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * (beemooCentered ? 0.45 : 0.32))
                        .position(
                            x: beemooCentered ? geo.size.width * 0.4 : geo.size.width * 0.24,
                            y: beemooCentered ? geo.size.height * 0.25 : geo.size.height * 0.08
                        )
                }

                // Go button (intro)
                if showActionButton {
                    Button { startClimbing() } label: {
                        Text("Start climbing!")
                            .font(.baloo2(24))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.bmConceptGreen))
                            .bmRaisedShadow()
                    }
                    .buttonStyle(.plain)
                    .position(x: geo.size.width * 0.25, y: geo.size.height * 0.82)
                    .transition(.scale.combined(with: .opacity))
                }

                // Climbing: word card + mic + skip
                if phase == .climbing, let stimulus = currentStimulus {
                    wordCard(stimulus, size: geo.size)
                    micButton(size: geo.size)
                    skipButton(size: geo.size)
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
            phase = .intro
            startIntroNarration()
        }
        .onDisappear {
            narrationTrack.stop()
            wordRecognizer.stop()
        }
    }

    // MARK: - Tree

    private func treeView(size: CGSize) -> some View {
        RemoteImage(filename: config?.treeAsset ?? "")
            .scaledToFit()
            .frame(height: size.height * 0.92)
            .position(x: size.width * 0.7, y: size.height * 0.5)
            .allowsHitTesting(false)
    }

    // MARK: - Monkey (position driven by currentStep @State)

    private func monkeyView(size: CGSize) -> some View {
        let pos = monkeyScreenPosition(step: currentStep, size: size)
        return RemoteImage(filename: config?.crouchAsset ?? "")
            .scaledToFit()
            .frame(height: size.height * 0.12)
            .position(pos)
            .animation(.spring(duration: 0.5, bounce: 0.3), value: currentStep)
            .allowsHitTesting(false)
    }

    private func monkeyScreenPosition(step: Int, size: CGSize) -> CGPoint {
        guard let config, step < config.steps.count else {
            return CGPoint(x: size.width * 0.7, y: size.height * 0.88)
        }
        let stepData = config.steps[step]
        let treeH = size.height * 0.92
        let treeW = treeH * (config.tw / config.th)
        let treeCenterX = size.width * 0.7
        let treeLeft = treeCenterX - treeW / 2
        let treeTop = (size.height - treeH) / 2
        let x = treeLeft + CGFloat(stepData.x) * treeW
        let y = treeTop + CGFloat(stepData.topY) * treeH - size.height * 0.06
        return CGPoint(x: x, y: y)
    }

    // MARK: - BEEMOO

    private func beemooMascot(size: CGSize) -> some View {
        RemoteImage(filename: "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? size.width * 0.18 : size.width * 0.08,
                height: beemooCentered ? size.height * 0.38 : size.height * 0.18
            )
            .position(
                x: beemooCentered ? size.width * 0.15 : size.width * 0.06,
                y: beemooCentered ? size.height * 0.48 : size.height * 0.14
            )
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Word Card

    private func wordCard(_ stimulus: StimulusConfig, size: CGSize) -> some View {
        VStack(spacing: 8) {
            ZStack {
                ZStack {
                    Color.white
                    RemoteImage(filename: stimulus.wordImage)
                        .scaledToFit()
                        .padding(16)
                }
                .drawingGroup()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                CardFrame(cornerRadius: 16, borderWidth: 6)
            }
            .frame(width: size.width * 0.24, height: size.height * 0.4)

            HStack(spacing: 8) {
                Button {
                    narrationTrack.speak(stimulus.targetWord, onWord: { _ in }, onFinish: {})
                } label: {
                    RemoteImage(filename: "ui/speaker_button.png")
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)

                Text(stimulus.targetWord.capitalized)
                    .font(.baloo2(20))
                    .foregroundStyle(Color.bmNavy)
            }
        }
        .position(x: size.width * 0.18, y: size.height * 0.5)
    }

    // MARK: - Mic Button

    private func micButton(size: CGSize) -> some View {
        Button {
            if wordRecognizer.isListening {
                // Already listening — do nothing, wait for recognition
            } else {
                startListening()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(wordRecognizer.isListening ? Color.bmOrange : Color.bmBlue)
                    .frame(width: 56, height: 56)
                Image(systemName: wordRecognizer.isListening ? "waveform" : "mic.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .bmRaisedShadow()
        }
        .buttonStyle(.plain)
        .position(x: size.width * 0.18, y: size.height * 0.85)
    }

    // MARK: - Skip Button

    private func skipButton(size: CGSize) -> some View {
        Button { handleSkip() } label: {
            Text("Skip")
                .font(.nunito(14, weight: .bold))
                .foregroundStyle(Color.bmNavy62)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(.white.opacity(0.8)))
        }
        .buttonStyle(.plain)
        .position(x: size.width * 0.30, y: size.height * 0.85)
    }

    // MARK: - Speech Recognition

    private func startListening() {
        guard let target = currentStimulus?.targetWord.lowercased() else { return }

        wordRecognizer.startListening { spokenText in
            // Check if the target word appears in what was recognized
            if spokenText.contains(target) {
                wordRecognizer.stop()
                handleCorrect()
            }
        }
    }

    private func handleCorrect() {
        guard let stimulus = currentStimulus else { return }
        logTrial(stimulus: stimulus, outcome: "correct")
        sfxPlayer.play("sfx/correct.mp3", from: apiClient)
        jumpMonkey()
    }

    private func handleSkip() {
        wordRecognizer.stop()
        guard let stimulus = currentStimulus else { return }
        logTrial(stimulus: stimulus, outcome: "skip")
        jumpMonkey()
    }

    private func jumpMonkey() {
        guard currentStep + 1 < totalSteps else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            currentStep += 1
        }
        sfxPlayer.play("sfx/popEffect.mp3", from: apiClient)
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            advanceStimulus()
        }
    }

    private func advanceStimulus() {
        let next = currentStimulusIndex + 1
        if next >= stimuli.count || currentStep >= totalSteps - 1 {
            phase = .complete
            Task {
                try? await Task.sleep(for: .milliseconds(1500))
                onAdvance()
            }
            return
        }
        currentStimulusIndex = next
        trialId = UUID()
        startListening()
    }

    private func logTrial(stimulus: StimulusConfig, outcome: String) {
        trialLogger.log(TrialRecord(
            id: trialId, screenId: screen.n, activityId: activityId,
            concept: screen.concept, firstTry: true, attempts: 1, timestamp: Date(),
            stimulusId: stimulus.stimulusId, targetWord: stimulus.targetWord,
            targetPosition: stimulus.targetPosition, stimulusType: "word",
            firstAttemptOutcome: outcome
        ))
    }

    // MARK: - Narration

    private func startIntroNarration() {
        let text = "Help the monkey climb the tree! Say the words!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
        Task {
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.35)) { showActionButton = true }
        }
    }

    private func startClimbing() {
        withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
            phase = .climbing
            showActionButton = false
        }
        let text = "Say the word!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            startListening()
        }
    }
}
