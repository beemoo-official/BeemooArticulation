import SwiftUI

/// Level 1 — Make the S Sound.
/// First screen: intro phase (BEEMOO centered, "Let's make the S sound!", Go button).
/// Each screen: game phase with BEEMOO top-left.
/// On completion: celebration phase (BEEMOO returns to center, "Great Job!", Continue button).
/// Three game variants: spot tap (0), snake drag (1), egg hatch (2).
struct SoundModelingScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void
    let isFirstScreen: Bool

    @Environment(APIClient.self) private var apiClient

    @State private var phase: Phase = .game  // overridden to .intro in onAppear if first screen
    @State private var interactionCount = 0
    @State private var completedSpots: Set<String> = []
    @State private var bubbleVM: NarratedBubbleVM?
    /// BEEMOO's voice: pre-recorded clips (voice/beemoo/…), falling back to the system voice. Set on appear.
    @State private var narrationTrack: any NarrationTrack = SystemNarrationTrack()
    @State private var popPlayer = RemoteAudioPlayer()
    @State private var showActionButton = false

    private let maxInteractions = 4

    enum Phase {
        case intro        // BEEMOO centered, "Let's make the S sound!", Go button
        case game         // BEEMOO top-left, game content visible
        case celebration  // BEEMOO returns to center, "Great Job!", Continue button
    }

    private var beemooCentered: Bool {
        phase == .intro || phase == .celebration
    }

    var body: some View {
        GeometryReader { geo in
            let layout = SoundLayout(size: geo.size)
            ZStack {
                // BEEMOO mascot
                beemooMascot(layout)

                // Speech bubble — above the big BEEMOO (intro/celebration) or beside the small one (game)
                if let vm = bubbleVM {
                    speechBubble(vm: vm, layout: layout)
                }

                // Action button (Go or Continue)
                if showActionButton {
                    actionButton(layout)
                        .transition(.scale.combined(with: .opacity))
                }

                // Game content (game phase only), in the area below BEEMOO's row
                if phase == .game {
                    gameContent(size: layout.gameRect.size)
                        .frame(width: layout.gameRect.width, height: layout.gameRect.height)
                        .position(x: layout.gameRect.midX, y: layout.gameRect.midY)
                        .transition(.opacity)
                }
            }
        }
        .background { JungleBackground() }
        .onAppear {
            narrationTrack = VoiceClipNarrationTrack(apiClient: apiClient)
            if isFirstScreen {
                phase = .intro
                startIntroNarration()
            } else {
                // Start centered briefly, then animate to game position
                phase = .celebration  // reuse centered position
                bubbleVM = nil
                Task {
                    try? await Task.sleep(for: .milliseconds(100))
                    withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                        phase = .game
                    }
                    try? await Task.sleep(for: .milliseconds(500))
                    startGameNarration()
                }
            }
        }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - BEEMOO mascot

    private func beemooMascot(_ layout: SoundLayout) -> some View {
        RemoteImage(filename: "mascot/BEEMOO_04_Smiling_Happy.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? layout.heroSize.width : layout.beemooSize,
                height: beemooCentered ? layout.heroSize.height : layout.beemooSize
            )
            .position(beemooCentered ? layout.heroCenter : layout.beemooCenter)
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Speech bubble

    @ViewBuilder
    private func speechBubble(vm: NarratedBubbleVM, layout: SoundLayout) -> some View {
        if beemooCentered {
            // Bottom of the bubble sits just above BEEMOO's head, tail pointing down at it
            VStack(spacing: -2) {
                NarratedBubble(vm: vm, contentWidth: layout.heroBubbleWidth, centered: true)
                SpeechTail()
                    .fill(.white)
                    .overlay { SpeechTail().stroke(Color.bmYellow, lineWidth: 3) }
                    .frame(width: 12, height: 18)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18, height: 12)
            }
            .frame(width: layout.size.width, height: layout.heroTop - 4, alignment: .bottom)
            .position(x: layout.size.width / 2, y: (layout.heroTop - 4) / 2)
        } else {
            HStack(spacing: -2) {
                SpeechTail()
                    .fill(.white)
                    .overlay { SpeechTail().stroke(Color.bmYellow, lineWidth: 3) }
                    .frame(width: 12, height: 18)
                    .zIndex(1)
                NarratedBubble(vm: vm, contentWidth: layout.bubbleWidth)
            }
            .frame(width: layout.bubbleWidth + 10, alignment: .leading)
            .position(x: layout.bubbleLeft + (layout.bubbleWidth + 10) / 2, y: layout.beemooCenter.y)
        }
    }

    // MARK: - Action button (Go / Continue)

    private func actionButton(_ layout: SoundLayout) -> some View {
        Button {
            if phase == .intro {
                transitionToGame()
            } else if phase == .celebration {
                // Continue to next screen
                withAnimation(.spring(duration: 0.4)) {
                    showActionButton = false
                }
                onAdvance()
            }
        } label: {
            Text(phase == .intro ? "Go!" : "Continue")
                .font(.baloo2(24))
                .foregroundStyle(.white)
                .frame(width: phase == .intro ? 120 : 160, height: 52)
                .background(Capsule().fill(Color.bmConceptGreen))
                .bmRaisedShadow()
        }
        .buttonStyle(.plain)
        .position(x: layout.size.width / 2, y: layout.actionY)
    }

    // MARK: - Transitions

    private func transitionToGame() {
        withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
            phase = .game
            showActionButton = false
        }
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            startGameNarration()
        }
    }

    private func transitionToCelebration() {
        withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
            phase = .celebration
            bubbleVM = nil
        }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            startCelebrationNarration()
        }
    }

    // MARK: - Game variants

    @ViewBuilder
    private func gameContent(size: CGSize) -> some View {
        let variant = screen.variant ?? 0
        switch variant {
        case 0:
            if let spotMap = screen.spotMap {
                SpotTapGame(
                    size: size,
                    spotMap: spotMap,
                    completedSpots: $completedSpots,
                    onSpotTapped: {
                        popPlayer.play("sfx/popEffect.mp3", from: apiClient)
                        handleInteraction()
                    }
                )
            }
        case 1:
            if let dragConfig = screen.dragToGoal {
                DragToGoalView(
                    config: dragConfig,
                    screenSize: size,
                    onItemDropped: { _ in
                        popPlayer.play("sfx/popEffect.mp3", from: apiClient)
                        handleInteraction()
                    },
                    showDebug: false
                )
            }
        default:
            EggHatchGame(size: size, onCrack: {
                popPlayer.play("sfx/eggCrack.mp3", from: apiClient)
            }, onHatch: {
                popPlayer.play("sfx/eggCrack.mp3", from: apiClient)
                handleInteraction()
            })
        }
    }

    // MARK: - Interaction handling

    private func handleInteraction() {
        interactionCount += 1
        if interactionCount >= totalInteractions {
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                transitionToCelebration()
            }
        }
    }

    /// Total interactions is driven by data for variants 0 and 1, or egg count for variant 2.
    private var totalInteractions: Int {
        switch screen.variant {
        case 0:
            return screen.spotMap?.spots.count ?? maxInteractions
        case 1:
            return screen.dragToGoal?.items.count ?? maxInteractions
        case 2:
            return 3
        default:
            return maxInteractions
        }
    }

    // MARK: - Narration

    private func startIntroNarration() {
        let text = "Let's make the *S* sound!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()

        Task {
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.35)) {
                showActionButton = true
            }
        }
    }

    private func startGameNarration() {
        let text = screen.displayText ?? "Say *S* and play!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }

    private func startCelebrationNarration() {
        let text = "Great job!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()

        Task {
            while !(bubbleVM?.narrationFinished ?? true) {
                try? await Task.sleep(for: .milliseconds(50))
            }
            withAnimation(.spring(duration: 0.35)) {
                showActionButton = true
            }
        }
    }
}

// MARK: - Spot Tap Game (variant 0)

private struct SpotTapGame: View {
    let size: CGSize
    let spotMap: SpotMap
    @Binding var completedSpots: Set<String>
    let onSpotTapped: () -> Void

    var body: some View {
        SpotTargetImage(
            spotMap: spotMap,
            completedSpots: completedSpots,
            onTap: { spot in
                withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                    completedSpots.insert(spot.id)
                }
                onSpotTapped()
            },
            showDebug: false
        )
        .frame(width: artSize.width, height: artSize.height)
        // Center the visible snake, not the padded image
        .position(
            x: size.width / 2 + (0.5 - content.midX) * artSize.width,
            y: size.height / 2 + (0.5 - content.midY) * artSize.height
        )
    }

    private var content: CGRect { spotMap.contentRect }

    /// Image size such that the visible snake fills the game area, whichever of width or height
    /// binds first. Phones use nearly all of it (spots need to stay ~40pt to tap); iPads leave
    /// more breathing room since spots are already large.
    private var artSize: CGSize {
        let isPhone = size.height < 450
        let maxContentW = size.width * (isPhone ? 0.88 : 0.8)
        let maxContentH = size.height * (isPhone ? 0.94 : 0.86)
        let contentAspect = spotMap.aspectRatio * content.width / content.height
        let contentW = min(maxContentW, maxContentH * contentAspect)
        let imageW = contentW / content.width
        return CGSize(width: imageW, height: imageW / spotMap.aspectRatio)
    }
}

// MARK: - Egg Hatch Game (variant 2)

private struct EggHatchGame: View {
    let size: CGSize
    let onCrack: () -> Void
    let onHatch: () -> Void

    @State private var eggStates: [Int] = [0, 0, 0]
    @State private var eggScales: [CGFloat] = [1, 1, 1]

    private let eggFilenames = [
        "s-sound/level1/Level1_SnakeEgg_Whole.png",
        "s-sound/level1/Level1_SnakeEgg_Cracked.png",
        "s-sound/level1/Level1_SnakeEgg_Hatched.png"
    ]

    private func eggPosition(_ index: Int) -> CGPoint {
        let xPositions: [CGFloat] = [0.22, 0.50, 0.78]
        return CGPoint(x: size.width * xPositions[index], y: size.height * 0.5)
    }

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                eggView(index: i)
            }
        }
    }

    private func eggView(index i: Int) -> some View {
        RemoteImage(filename: eggFilenames[eggStates[i]])
            .scaledToFit()
            .frame(maxWidth: size.width * 0.26, maxHeight: size.height * 0.85)
            .scaleEffect(eggScales[i])
            .position(eggPosition(i))
            .onTapGesture {
                guard eggStates[i] < 2 else { return }

                withAnimation(.spring(duration: 0.25, bounce: 0.5)) {
                    eggScales[i] = 1.15
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation(.spring(duration: 0.3)) {
                        eggScales[i] = 1.0
                    }
                }

                if eggStates[i] == 0 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        eggStates[i] = 1
                    }
                    onCrack()
                } else if eggStates[i] == 1 {
                    withAnimation(.spring(duration: 0.35, bounce: 0.4)) {
                        eggStates[i] = 2
                    }
                    onHatch()
                }
            }
    }
}

// MARK: - Layout

/// Landscape metrics. Game phase: small BEEMOO + bubble in a row at the top (clear of the runner's
/// home button), the mini-game filling the area below.
/// Intro/celebration: big BEEMOO centered, bubble above it, Go/Continue below it.
private struct SoundLayout {
    let size: CGSize

    /// iPhone landscape (short screens)
    var isCompact: Bool { size.height < 600 }
    var margin: CGFloat { isCompact ? 10 : 24 }

    // Game phase: top row
    var beemooSize: CGFloat { min(max(size.height * 0.15, 56), 120) }
    /// BEEMOO starts right of the runner's 44pt home button (RunnerChrome)
    private var beemooLeft: CGFloat { isCompact ? 58 : 72 }
    /// Tall enough for a two-line bubble next to BEEMOO
    private var rowHeight: CGFloat { max(beemooSize, isCompact ? 76 : 100) }
    var beemooCenter: CGPoint { CGPoint(x: beemooLeft + beemooSize / 2, y: margin + rowHeight / 2) }
    var bubbleLeft: CGFloat { beemooLeft + beemooSize + 2 }
    /// Leaves room for the runner's progress pill in the top-right corner
    var bubbleWidth: CGFloat { min(size.width - bubbleLeft - 100, 560) }

    /// Everything below BEEMOO's row, down to the bottom margin
    var gameRect: CGRect {
        let top = margin + rowHeight + (isCompact ? 4 : 12)
        return CGRect(x: 0, y: top, width: size.width, height: size.height - margin - top)
    }

    // Intro / celebration
    var heroSize: CGSize { CGSize(width: size.width * 0.34, height: size.height * 0.5) }
    var heroCenter: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.52) }
    var heroTop: CGFloat { heroCenter.y - heroSize.height / 2 }
    var heroBubbleWidth: CGFloat { min(size.width * 0.6, 480) }
    var actionY: CGFloat { size.height - margin - 26 - (isCompact ? 0 : 16) }
}

/// Small left-pointing tail that connects a bubble to BEEMOO.
private struct SpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}
