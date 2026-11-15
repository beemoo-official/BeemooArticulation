import SwiftUI
import UIKit
import AVFoundation
import Speech

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
    /// True while the current word is waiting to be said (or skipped). Guards against double triggers.
    @State private var awaitingWord = false

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var sfxPlayer = RemoteAudioPlayer()

    // Tree + monkey physics scene (MonkeyClimbModel.swift), stepped every frame by the display link
    @State private var climb: MonkeyClimbState?
    @State private var frameDriver = FrameDriver()
    /// Where the camera's center sits across the screen, so the tree and monkey stay right of the word card.
    private let sceneAnchorX: CGFloat = 0.66

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
                // Tree, monkey and leaves, drawn from the physics model
                climbScene

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
            .onAppear { setUpScene(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                climb?.updateScreenSize(screenW: newSize.width, screenH: newSize.height)
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
            frameDriver.stop()
        }
    }

    // MARK: - Climb scene (tree, monkey, leaves)

    private func setUpScene(size: CGSize) {
        guard climb == nil, let config else { return }
        let state = MonkeyClimbState(config: config)
        state.onLand = { reachedTop in handleLanding(reachedTop: reachedTop) }
        climb = state
        frameDriver.onFrame = { dt in state.tick(dt: dt) }
        frameDriver.start()
        Task {
            await state.preload(apiClient: apiClient)
            // Setup camera AFTER preload so monkey position is known
            state.setupCamera(screenW: size.width, screenH: size.height)
        }
    }

    @ViewBuilder
    private var climbScene: some View {
        if let climb, climb.isReady {
            TimelineView(.animation) { _ in
                Canvas { ctx, size in
                    drawScene(climb, in: &ctx, size: size)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    /// Draws in "world units" (pixels of the tree image) through a camera transform.
    /// The monkey is always anchored at its feet, so squash, stretch and lean pivot on the plank.
    private func drawScene(_ m: MonkeyClimbState, in ctx: inout GraphicsContext, size: CGSize) {
        guard let tree = m.treeImage else { return }
        let zoom = m.zoom * (1 + m.punch)

        var world = ctx
        world.translateBy(x: size.width * sceneAnchorX, y: size.height / 2)
        world.scaleBy(x: zoom, y: zoom)
        world.translateBy(x: -m.camX, y: -m.camY)

        world.draw(Image(uiImage: tree), in: CGRect(x: 0, y: 0, width: m.tw, height: m.th))

        // Monkey
        let airborne = m.showsJumpFrame
        if let image = (airborne ? m.jumpImage : m.crouchImage) ?? m.crouchImage {
            let scale = m.monkeyScale
            let h = m.monkeyHeight * (airborne ? 1.06 : 1) * scale
            let w = h * image.size.width / max(image.size.height, 1)
            let s = max(m.s, 0.01)

            var monkey = world
            monkey.translateBy(x: m.monkeyX, y: m.monkeyFeetY)
            monkey.rotate(by: .radians(Double(m.lean)))
            // Shadow removed
            monkey.scaleBy(x: m.facing / sqrt(s), y: s)
            monkey.draw(Image(uiImage: image), in: CGRect(x: -w / 2, y: -h, width: w, height: h))
        }

        // Leaves
        for leaf in m.leaves {
            var l = world
            l.opacity = Double(leaf.alpha)
            l.translateBy(x: leaf.x, y: leaf.y)
            l.rotate(by: .radians(Double(leaf.rotation)))
            l.fill(
                Path(ellipseIn: CGRect(x: -leaf.size, y: -leaf.size * 0.55, width: leaf.size * 2, height: leaf.size * 1.1)),
                with: .color(Color(uiColor: leaf.color))
            )
        }
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
                    // Pause listening while the app says the word, so it can't hear itself.
                    wordRecognizer.stop()
                    narrationTrack.speak(stimulus.targetWord, onWord: { _ in }, onFinish: {
                        if awaitingWord { listenForCurrentWord() }
                    })
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

    /// Speech mode: tap to start listening; tap while listening to confirm the word yourself.
    /// Manual mode (simulator, or no speech permission): tap when the child says the word.
    private func micButton(size: CGSize) -> some View {
        let manual = wordRecognizer.mode == .manual
        let listening = wordRecognizer.isListening
        return Button {
            if manual || listening {
                handleCorrect()
            } else {
                listenForCurrentWord()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(listening ? Color.bmOrange : Color.bmBlue)
                        .frame(width: 56, height: 56)
                    Image(systemName: manual ? "checkmark" : (listening ? "waveform" : "mic.fill"))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: listening)
                }
                .bmRaisedShadow()
                Text(manual ? "They said it" : (listening ? "Listening…" : "Tap to listen"))
                    .font(.nunito(12, weight: .bold))
                    .foregroundStyle(Color.bmNavy)
                if listening, !wordRecognizer.lastHeard.isEmpty {
                    Text("Heard: \"\(wordRecognizer.lastHeard)\"")
                        .font(.nunito(11, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .frame(maxWidth: 220)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!awaitingWord)
        .opacity(awaitingWord ? 1 : 0.5)
        .accessibilityLabel(manual ? "They said the word" : (listening ? "Listening. Tap to confirm the word" : "Start listening"))
        .position(x: size.width * 0.18, y: size.height * 0.86)
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

    // MARK: - Word lifecycle
    // listen → word heard (or adult taps / Skip) → stop → jump → landing → next word → listen again

    private func listenForCurrentWord() {
        guard phase == .climbing, let word = currentStimulus?.targetWord else { return }
        awaitingWord = true
        wordRecognizer.listen(for: word) { handleCorrect() }
    }

    private func handleCorrect() {
        guard awaitingWord, let stimulus = currentStimulus else { return }
        awaitingWord = false
        wordRecognizer.stop()
        logTrial(stimulus: stimulus, outcome: "correct")
        sfxPlayer.play("sfx/correct.mp3", from: apiClient)
        jumpMonkey()
    }

    private func handleSkip() {
        guard awaitingWord, let stimulus = currentStimulus else { return }
        awaitingWord = false
        wordRecognizer.stop()
        logTrial(stimulus: stimulus, outcome: "skip")
        jumpMonkey()
    }

    private func jumpMonkey() {
        guard let climb, climb.phase == .idle, climb.currentStep + 1 < totalSteps else { return }
        climb.triggerJump()   // wind-up, arc, landing: all run in the physics model
    }

    /// Called by the physics model when the monkey's feet touch the next plank.
    private func handleLanding(reachedTop: Bool) {
        currentStep = climb?.currentStep ?? currentStep
        sfxPlayer.play("sfx/popEffect.mp3", from: apiClient)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        Task {
            try? await Task.sleep(for: .milliseconds(reachedTop ? 0 : 350))
            advanceStimulus()
        }
    }

    private func advanceStimulus() {
        let next = currentStimulusIndex + 1
        if next >= stimuli.count || currentStep >= totalSteps - 1 {
            phase = .complete
            Task {
                try? await Task.sleep(for: .milliseconds(2600))
                onAdvance()
            }
            return
        }
        currentStimulusIndex = next
        trialId = UUID()
        listenForCurrentWord()
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
        climb?.startClimbing()
        let text = "Say the word!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            listenForCurrentWord()
        }
    }
}
