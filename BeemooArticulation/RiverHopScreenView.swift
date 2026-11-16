import SwiftUI
import UIKit

// MARK: - Elephant River Hop Screen
// The child says each word; the elephant hops to the next stone. 9 stones, the 10th hop lands on the far bank.
// Word card, mic, Skip, BEEMOO and narration behave exactly like MonkeyClimbScreenView.

struct RiverHopScreenView: View {
    let screen: ScreenConfig
    let activityId: String
    let settings: RunnerSettings
    let trialLogger: TrialLogger
    let onAdvance: () -> Void

    @Environment(APIClient.self) private var apiClient

    @State private var phase: Phase = .intro
    @State private var currentStimulusIndex = 0
    @State private var hopsDone = 0
    @State private var trialId = UUID()
    @State private var showActionButton = false
    @State private var wordRecognizer = WordRecognizer()
    /// True while the current word is waiting to be said (or skipped). Guards against double triggers.
    @State private var awaitingWord = false

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var sfxPlayer = RemoteAudioPlayer()
    @State private var praise = PraisePlayer()

    // River + elephant physics scene (RiverHopModel.swift), stepped every frame by the display link
    @State private var river: RiverHopState?
    @State private var frameDriver = FrameDriver()

    private var config: RiverHopConfig? { screen.riverHop }
    private var stimuli: [StimulusConfig] { screen.stimuli ?? [] }
    private var currentStimulus: StimulusConfig? {
        guard currentStimulusIndex < stimuli.count else { return nil }
        return stimuli[currentStimulusIndex]
    }
    private var totalHops: Int { river?.hopCount ?? (config.map { $0.stones.count + 1 } ?? 1) }

    enum Phase { case intro, climbing, complete }
    private var beemooCentered: Bool { phase == .intro }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // River, stones, elephant and splashes, drawn from the physics model
                riverScene

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

                // Start button (intro)
                if showActionButton {
                    Button { startHopping() } label: {
                        Text("Start hopping!")
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

                // Hopping: word card + mic + skip
                if phase == .climbing, let stimulus = currentStimulus {
                    wordCard(stimulus, size: geo.size)
                    micButton(size: geo.size)
                    skipButton(size: geo.size)
                }
            }
            .onAppear { setUpScene(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                river?.updateScreenSize(screenW: newSize.width, screenH: newSize.height)
            }
        }
        .background { JungleBackground() }   // shown only until the river images have loaded
        .onAppear {
            praise.configure(apiClient: apiClient)
            phase = .intro
            startIntroNarration()
        }
        .onDisappear {
            narrationTrack.stop()
            praise.stop()
            wordRecognizer.stop()
            frameDriver.stop()
        }
    }

    // MARK: - River scene

    private func setUpScene(size: CGSize) {
        guard river == nil, let config else { return }
        let state = RiverHopState(config: config)
        state.onLand = { reachedEnd in handleLanding(reachedEnd: reachedEnd) }
        state.updateScreenSize(screenW: size.width, screenH: size.height)
        river = state
        frameDriver.onFrame = { dt in state.tick(dt: dt) }
        frameDriver.start()
        Task { await state.preload(apiClient: apiClient) }
    }

    @ViewBuilder
    private var riverScene: some View {
        if let river, river.isReady {
            TimelineView(.animation) { _ in
                Canvas { ctx, size in
                    drawScene(river, in: &ctx, size: size)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    /// Draws in world units (pixels of the river background) through the camera.
    /// The elephant is anchored at its feet, so squash, stretch and lean pivot on the stone.
    private func drawScene(_ m: RiverHopState, in ctx: inout GraphicsContext, size: CGSize) {
        guard let background = m.backgroundImage, let stoneImage = m.stoneImage else { return }
        let zoom = m.zoom * (1 + m.punch)

        var world = ctx
        world.translateBy(x: size.width * m.anchorX, y: size.height / 2)
        world.scaleBy(x: zoom, y: zoom)
        world.translateBy(x: -m.camX, y: -m.camY)

        world.draw(Image(uiImage: background), in: CGRect(x: 0, y: 0, width: m.bw, height: m.bh))

        // Ripples under the stones
        for r in m.ripples where r.age >= 0 {
            let u = r.age / r.lifetime
            let rx = 30 + u * 50, ry = 8 + u * 13
            world.stroke(
                Path(ellipseIn: CGRect(x: r.x - rx, y: r.y - ry, width: rx * 2, height: ry * 2)),
                with: .color(.white.opacity(Double(0.7 * (1 - u)))),
                lineWidth: 3 * (1 - u) + 0.5
            )
        }

        // Stones: the landing point (50% across, stoneLandingY down) sits on each stone position
        let sw = CGFloat(m.config.stoneWidth)
        let sh = sw * stoneImage.size.height / max(stoneImage.size.width, 1)
        let landingY = CGFloat(m.config.stoneLandingY)
        for (k, stone) in m.config.stones.enumerated() {
            let rect = CGRect(x: stone.x - sw / 2, y: stone.y - landingY * sh + m.stoneDip[k], width: sw, height: sh)
            world.draw(Image(uiImage: stoneImage), in: rect)
        }

        // Elephant
        let airborne = m.showsJumpFrame
        if let image = (airborne ? m.jumpImage : m.standImage) ?? m.standImage {
            let h = m.elephantHeight * (airborne ? 1.04 : 1)
            let w = h * image.size.width / max(image.size.height, 1)
            let s = max(m.s, 0.01)
            let stone = m.index - 1
            let sink: CGFloat = (!airborne && stone >= 0 && stone < m.stoneDip.count) ? m.stoneDip[stone] : 0

            var elephant = world
            elephant.translateBy(x: m.pos.x, y: m.pos.y + sink)
            elephant.rotate(by: .radians(Double(m.lean)))
            elephant.scaleBy(x: 1 / sqrt(s), y: s)
            elephant.draw(Image(uiImage: image), in: CGRect(x: -w / 2, y: -h, width: w, height: h))
        }

        // Splash drops and confetti
        for d in m.drops {
            var p = world
            p.opacity = Double(d.alpha)
            p.translateBy(x: d.x, y: d.y)
            if d.isConfetti {
                p.rotate(by: .radians(Double(d.rotation)))
                p.fill(Path(CGRect(x: -d.radius, y: -d.radius * 0.5, width: d.radius * 2, height: d.radius)),
                       with: .color(Color(uiColor: d.color)))
            } else {
                p.fill(Path(ellipseIn: CGRect(x: -d.radius, y: -d.radius, width: d.radius * 2, height: d.radius * 2)),
                       with: .color(Color(uiColor: d.color)))
            }
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
        praise.play()
        hopElephant()
    }

    private func handleSkip() {
        guard awaitingWord, let stimulus = currentStimulus else { return }
        awaitingWord = false
        wordRecognizer.stop()
        logTrial(stimulus: stimulus, outcome: "skip")
        hopElephant()
    }

    private func hopElephant() {
        guard let river, river.phase == .idle, river.index < river.hopCount else { return }
        river.triggerHop()   // wind-up, arc, landing: all run in the physics model
    }

    /// Called by the physics model when the elephant's feet touch the next stone or the far bank.
    private func handleLanding(reachedEnd: Bool) {
        hopsDone = river?.index ?? hopsDone
        sfxPlayer.play("sfx/popEffect.mp3", from: apiClient)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        Task {
            try? await Task.sleep(for: .milliseconds(reachedEnd ? 0 : 350))
            advanceStimulus()
        }
    }

    private func advanceStimulus() {
        let next = currentStimulusIndex + 1
        if next >= stimuli.count || hopsDone >= totalHops {
            phase = .complete
            Task {
                try? await Task.sleep(for: .milliseconds(2600))   // let the pull-back and confetti play
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
        let text = screen.text ?? "Help the elephant cross the river! Say the words!"
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

    private func startHopping() {
        withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
            phase = .climbing
            showActionButton = false
        }
        river?.startHopping()
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
