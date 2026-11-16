import SwiftUI
import UIKit

// MARK: - Elephant River Hop Screen
// The child says each word; the elephant hops to the next stone. 9 stones, the 10th hop lands on the far bank.
// Word panel, listening meter, Skip, BEEMOO and narration are shared with MonkeyClimbScreenView (WordPracticeUI.swift).

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
    /// BEEMOO's voice: pre-recorded clips (voice/beemoo/…), falling back to the system voice. Set on appear.
    @State private var narrationTrack: any NarrationTrack = SystemNarrationTrack()
    @State private var sfxPlayer = RemoteAudioPlayer()
    @State private var praise = PraisePlayer()
    @State private var music = BackgroundMusicPlayer()

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
            let layout = WordPracticeLayout(size: geo.size)
            ZStack {
                // River, stones, elephant and splashes, drawn full-screen from the physics model
                riverScene

                // BEEMOO mascot
                beemooMascot(size: geo.size, layout: layout)

                // Speech bubble: beside the big BEEMOO (intro) or the small one (hopping)
                if let vm = bubbleVM {
                    if beemooCentered {
                        WordPracticeBubble(
                            vm: vm,
                            width: min(geo.size.width * 0.42, 360),
                            left: introBubbleLeft(geo.size),
                            centerY: geo.size.height * 0.26
                        )
                    } else {
                        WordPracticeBubble(vm: vm, layout: layout)
                    }
                }

                // Start button (intro): under the bubble, above the water, clear of the elephant on the bank
                if showActionButton {
                    Button { startHopping() } label: {
                        Text("Start hopping!")
                            .font(.baloo2(layout.isCompact ? 22 : 26))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, layout.isCompact ? 10 : 14)
                            .background(Capsule().fill(Color.bmConceptGreen))
                            .bmRaisedShadow()
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .frame(width: geo.size.width * 0.42, alignment: .leading)
                    .position(x: introBubbleLeft(geo.size) + 12 + geo.size.width * 0.21, y: geo.size.height * 0.5)
                    .transition(.scale.combined(with: .opacity))
                }

                // Hopping: word panel + Skip
                if phase == .climbing, let stimulus = currentStimulus {
                    WordPracticePanel(
                        stimulus: stimulus,
                        layout: layout,
                        recognizer: wordRecognizer,
                        awaitingWord: awaitingWord,
                        onSpeaker: {
                            // Pause listening while the app says the word, so it can't hear itself.
                            wordRecognizer.stop()
                            narrationTrack.speak(stimulus.targetWord, onWord: { _ in }, onFinish: {
                                if awaitingWord { listenForCurrentWord() }
                            })
                        },
                        onConfirm: { handleCorrect() }
                    )
                    WordPracticeSkipButton(layout: layout, enabled: awaitingWord) { handleSkip() }
                }
            }
            .onAppear { setUpScene(geo: geo, layout: layout) }
            .onChange(of: geo.size) { _, _ in fitScene(geo: geo, layout: WordPracticeLayout(size: geo.size)) }
        }
        .background { JungleBackground() }   // shown only until the river images have loaded
        .onAppear {
            praise.configure(apiClient: apiClient)
            narrationTrack = VoiceClipNarrationTrack(apiClient: apiClient)
            music.start("music/silly_walks.m4a", apiClient: apiClient)
            phase = .intro
            startIntroNarration()
        }
        .onDisappear {
            narrationTrack.stop()
            praise.stop()
            wordRecognizer.stop()
            frameDriver.stop()
            music.stop()
        }
        .onChange(of: wordRecognizer.isListening) { _, _ in music.resumeIfNeeded() }
    }

    /// The intro bubble's tail sits just right of the big BEEMOO
    private func introBubbleLeft(_ size: CGSize) -> CGFloat { size.width * 0.25 }

    // MARK: - River scene

    private func setUpScene(geo: GeometryProxy, layout: WordPracticeLayout) {
        guard river == nil, let config else { return }
        let state = RiverHopState(config: config)
        state.onLand = { reachedEnd in handleLanding(reachedEnd: reachedEnd) }
        river = state
        fitScene(geo: geo, layout: layout)
        frameDriver.onFrame = { dt in state.tick(dt: dt) }
        frameDriver.start()
        Task { await state.preload(apiClient: apiClient) }
    }

    /// The river is drawn edge to edge (under the safe areas), while the overlays stay inside them.
    /// Give the camera the full-screen size, and aim it at the middle of the area right of the word panel.
    private func fitScene(geo: GeometryProxy, layout: WordPracticeLayout) {
        guard let river else { return }
        let insets = geo.safeAreaInsets
        let fullW = geo.size.width + insets.leading + insets.trailing
        let fullH = geo.size.height + insets.top + insets.bottom
        let freeMinX = insets.leading + layout.columnMaxX
        let freeMaxX = insets.leading + geo.size.width
        river.anchorX = (freeMinX + freeMaxX) / 2 / max(fullW, 1)
        river.freeWidthFraction = (freeMaxX - freeMinX) / max(fullW, 1)
        river.updateScreenSize(screenW: fullW, screenH: fullH)
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
            // Pitch about the body's middle, not the feet, so it tips like a real jump
            let pivotY = -h * 0.45
            elephant.translateBy(x: 0, y: pivotY)
            elephant.rotate(by: .radians(Double(m.lean)))
            elephant.translateBy(x: 0, y: -pivotY)
            // Squash and stretch about the feet, keeping the volume
            elephant.scaleBy(x: 1 / sqrt(s), y: s)
            // The feet (not the image center) go on the stone
            let anchorX = airborne ? m.jumpAnchorX : m.standAnchorX
            elephant.draw(Image(uiImage: image), in: CGRect(x: -w * anchorX, y: -h, width: w, height: h))
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

    private func beemooMascot(size: CGSize, layout: WordPracticeLayout) -> some View {
        RemoteImage(filename: "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? size.width * 0.18 : layout.beemooSize,
                height: beemooCentered ? size.height * 0.36 : layout.beemooSize
            )
            .position(
                x: beemooCentered ? size.width * 0.15 : layout.beemooCenter.x,
                y: beemooCentered ? size.height * 0.4 : layout.beemooCenter.y
            )
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
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
        // On the last hop BEEMOO cheers when the elephant reaches the bank instead
        if !isFinalHop { praise.play() }
        hopElephant()
    }

    private func handleSkip() {
        guard awaitingWord, let stimulus = currentStimulus else { return }
        awaitingWord = false
        wordRecognizer.stop()
        logTrial(stimulus: stimulus, outcome: "skip")
        hopElephant()
    }

    private var isFinalHop: Bool {
        guard let river else { return false }
        return river.index + 1 >= river.hopCount || currentStimulusIndex + 1 >= stimuli.count
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
            let vm = NarratedBubbleVM(markerText: "You did it!", narrationTrack: narrationTrack)
            vm.isNarrationOff = !settings.narrationEnabled
            bubbleVM = vm
            vm.startNarration()
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
