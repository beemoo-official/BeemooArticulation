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
    /// BEEMOO's voice: pre-recorded clips (voice/beemoo/…), falling back to the system voice. Set on appear.
    @State private var narrationTrack: any NarrationTrack = SystemNarrationTrack()
    @State private var sfxPlayer = RemoteAudioPlayer()
    @State private var praise = PraisePlayer()
    @State private var music = BackgroundMusicPlayer()

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

                // Speech bubble — intro: beside the big BEEMOO; climbing: right of the small BEEMOO, tail pointing at it
                if let vm = bubbleVM {
                    let layout = ClimbLayout(size: geo.size)
                    if beemooCentered {
                        NarratedBubble(vm: vm, contentWidth: min(geo.size.width * 0.4, 320))
                            .position(x: geo.size.width * 0.38, y: geo.size.height * 0.22)
                    } else {
                        HStack(spacing: -2) {
                            BubbleTail()
                                .fill(.white)
                                .overlay { BubbleTail().stroke(Color.bmYellow, lineWidth: 3) }
                                .frame(width: 12, height: 18)
                                .zIndex(1)
                            NarratedBubble(vm: vm, contentWidth: layout.bubbleWidth)
                        }
                        .frame(width: layout.bubbleWidth + 10, alignment: .leading)
                        .position(x: layout.bubbleLeft + (layout.bubbleWidth + 10) / 2, y: layout.beemooCenter.y)
                    }
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

                // Climbing: unified left panel with word card + controls
                if phase == .climbing, let stimulus = currentStimulus {
                    climbingPanel(stimulus: stimulus, size: geo.size)
                }
            }
            .onAppear { setUpScene(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                climb?.updateScreenSize(screenW: newSize.width, screenH: newSize.height)
            }
        }
        .background { JungleBackground() }
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
        let layout = ClimbLayout(size: size)
        return RemoteImage(filename: "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? size.width * 0.18 : layout.beemooSize,
                height: beemooCentered ? size.height * 0.38 : layout.beemooSize
            )
            .position(
                x: beemooCentered ? size.width * 0.15 : layout.beemooCenter.x,
                y: beemooCentered ? size.height * 0.48 : layout.beemooCenter.y
            )
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Unified climbing panel (word card + controls)

    private func climbingPanel(stimulus: StimulusConfig, size: CGSize) -> some View {
        let layout = ClimbLayout(size: size)
        let compact = layout.isCompact
        let manual = wordRecognizer.mode == .manual
        let corner: CGFloat = compact ? 14 : 20

        return VStack(spacing: 0) {
            // Word card: image + word name inside, golden frame, speaker overlapping the bottom edge
            VStack(spacing: compact ? 2 : 6) {
                RemoteImage(filename: stimulus.wordImage)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(stimulus.targetWord.capitalized)
                    .font(.baloo2(compact ? 18 : 30))
                    .foregroundStyle(Color.bmNavy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.top, compact ? 10 : 16)
            // Leave room so the word sits above the half of the speaker that overlaps the card
            .padding(.bottom, layout.speakerSize / 2 + (compact ? 2 : 6))
            .frame(width: layout.cardSize.width, height: layout.cardSize.height)
            .background(RoundedRectangle(cornerRadius: corner).fill(.white))
            .overlay { CardFrame(cornerRadius: corner, borderWidth: compact ? 5 : 8) }
            .bmCardShadow()
            .overlay(alignment: .bottom) {
                Button {
                    wordRecognizer.stop()
                    narrationTrack.speak(stimulus.targetWord, onWord: { _ in }, onFinish: {
                        if awaitingWord { listenForCurrentWord() }
                    })
                } label: {
                    RemoteImage(filename: "ui/speaker_button.png")
                        .scaledToFit()
                        .frame(width: layout.speakerSize, height: layout.speakerSize)
                }
                .buttonStyle(.plain)
                .offset(y: layout.speakerSize / 2)
            }
            .padding(.bottom, layout.speakerSize / 2 + layout.controlGap)

            // Feedback that the mic hears the child. Read-only: it never advances the game.
            // Only if speech recognition is unavailable does it become the adult's "They said it" button.
            if manual {
                Button { handleCorrect() } label: {
                    Label("They said it", systemImage: "checkmark")
                        .font(.nunito(compact ? 13 : 17, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, compact ? 14 : 20)
                        .frame(height: layout.meterHeight)
                        .background(Capsule().fill(Color.bmConceptGreen).bmCardShadow())
                }
                .buttonStyle(.plain)
                .disabled(!awaitingWord)
                .opacity(awaitingWord ? 1 : 0.5)
            } else {
                ListeningMeter(recognizer: wordRecognizer, height: layout.meterHeight)
                    .opacity(awaitingWord ? 1 : 0.5)
            }
        }
        .frame(width: layout.columnWidth, height: layout.panelRect.height)
        .position(x: layout.panelRect.midX, y: layout.panelRect.midY)
        .overlay {
            // Skip lives bottom-right, away from the word panel
            Button { handleSkip() } label: {
                HStack(spacing: 4) {
                    Text("Skip")
                    Image(systemName: "forward.fill")
                        .font(.system(size: compact ? 11 : 14, weight: .bold))
                }
                .font(.nunito(compact ? 14 : 18, weight: .bold))
                .foregroundStyle(Color.bmNavy)
                .padding(.horizontal, compact ? 14 : 20)
                .padding(.vertical, compact ? 7 : 10)
                .background(Capsule().fill(.white.opacity(0.9)).bmCardShadow())
            }
            .buttonStyle(.plain)
            .disabled(!awaitingWord)
            .opacity(awaitingWord ? 1 : 0.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(layout.margin)
        }
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

// MARK: - Layout

/// Landscape metrics for the climbing phase. Left column = BEEMOO + bubble on top, word panel below;
/// the tree and monkey own the right side of the screen.
private struct ClimbLayout {
    let size: CGSize

    /// iPhone landscape (short screens). Width can't tell iPhone apart: an iPhone 17 is ~874pt wide.
    var isCompact: Bool { size.height < 600 }

    var margin: CGFloat { isCompact ? 10 : 24 }
    /// Left column, kept clear of the tree trunk (camera anchored at 0.66 of the width)
    var columnWidth: CGFloat { size.width * 0.40 - margin }

    var beemooSize: CGFloat { min(max(size.height * 0.15, 56), 120) }
    /// BEEMOO starts right of the runner's 44pt home button (RunnerChrome) so they never touch
    private var beemooLeft: CGFloat { isCompact ? 58 : 72 }
    var beemooCenter: CGPoint { CGPoint(x: beemooLeft + beemooSize / 2, y: margin + beemooSize / 2) }

    var bubbleLeft: CGFloat { beemooLeft + beemooSize + 2 }
    /// May run past the word column over open sky (the top of the tree sits further right),
    /// so short lines like "Say the word!" stay on one line instead of growing off the top.
    var bubbleWidth: CGFloat { min(size.width * 0.46 - bubbleLeft, 300) }

    var speakerSize: CGFloat { isCompact ? 36 : 56 }
    var meterHeight: CGFloat { isCompact ? 34 : 48 }
    var controlGap: CGFloat { isCompact ? 8 : 18 }

    /// Everything below the BEEMOO row
    var panelRect: CGRect {
        let top = margin + beemooSize + (isCompact ? 6 : 16)
        return CGRect(x: margin, y: top, width: columnWidth, height: size.height - top - margin)
    }

    /// Height used by the speaker overhang and the listening meter below the card
    private var controlsHeight: CGFloat { speakerSize / 2 + controlGap + meterHeight }

    var cardSize: CGSize {
        let maxH = panelRect.height - controlsHeight
        let maxW = columnWidth * (isCompact ? 0.78 : 0.9)
        // Slightly taller than wide so the image stays square-ish above the word
        let h = min(maxH, maxW * 1.15)
        return CGSize(width: min(maxW, h / 1.15 * (isCompact ? 1.25 : 1)), height: h)
    }
}

/// Small left-pointing tail that connects the climbing bubble to BEEMOO.
private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

/// Live mic level bars. Shows the child (and adult) that the app is actually hearing them.
private struct ListeningMeter: View {
    let recognizer: WordRecognizer
    let height: CGFloat

    /// Fixed per-bar shape so the bars read as a waveform, tallest in the middle
    private let weights: [CGFloat] = [0.45, 0.7, 0.9, 1, 0.9, 0.7, 0.45]

    var body: some View {
        let listening = recognizer.isListening
        let level = CGFloat(recognizer.level)
        let barMax = height * 0.55

        HStack(spacing: height * 0.22) {
            Image(systemName: "mic.fill")
                .font(.system(size: height * 0.4, weight: .semibold))
                .foregroundStyle(listening ? Color.bmBlue : Color.bmNavy50)

            HStack(spacing: height * 0.09) {
                ForEach(weights.indices, id: \.self) { i in
                    Capsule()
                        .fill(listening ? Color.bmBlue : Color.bmNavy50.opacity(0.5))
                        .frame(width: height * 0.1, height: max(height * 0.1, barMax * weights[i] * level))
                }
            }
            .frame(height: barMax)
            .animation(.easeOut(duration: 0.08), value: level)
        }
        .padding(.horizontal, height * 0.45)
        .frame(height: height)
        .background(Capsule().fill(.white.opacity(0.92)).bmCardShadow())
        .allowsHitTesting(false)
        .accessibilityElement()
        .accessibilityLabel(listening ? "Listening" : "Microphone off")
    }
}
