import SwiftUI

/// Level 1 — Make the S Sound.
/// First screen: intro phase (BEEMOO centered, "Let's make the ssssss sound!", Go button).
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
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var popPlayer = RemoteAudioPlayer()
    @State private var showActionButton = false

    private let maxInteractions = 4

    enum Phase {
        case intro        // BEEMOO centered, "Let's make the ssssss sound!", Go button
        case game         // BEEMOO top-left, game content visible
        case celebration  // BEEMOO returns to center, "Great Job!", Continue button
    }

    private var beemooCentered: Bool {
        phase == .intro || phase == .celebration
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // BEEMOO mascot
                beemooMascot(size: geo.size)

                // Speech bubble — near BEEMOO's mouth area
                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * (beemooCentered ? 0.5 : 0.4))
                        .position(
                            x: beemooCentered ? geo.size.width * 0.5 : geo.size.width * 0.32,
                            y: beemooCentered ? geo.size.height * 0.28 : 60
                        )
                }

                // Action button (Go or Continue)
                if showActionButton {
                    actionButton(size: geo.size)
                        .transition(.scale.combined(with: .opacity))
                }

                // Game content (game phase only)
                if phase == .game {
                    gameContent(size: geo.size)
                        .transition(.opacity)

                    // Progress indicator
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
        .background { JungleBackground() }
        .onAppear {
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

    private func beemooMascot(size: CGSize) -> some View {
        RemoteImage(filename: "BEEMOO_04_Smiling_Happy.png")
            .scaledToFit()
            .frame(
                width: beemooCentered ? size.width * 0.28 : size.width * 0.09,
                height: beemooCentered ? size.height * 0.55 : size.height * 0.22
            )
            .position(
                x: beemooCentered ? size.width * 0.5 : size.width * 0.065,
                y: beemooCentered ? size.height * 0.62 : size.height * 0.18
            )
            .animation(.spring(duration: 0.6, bounce: 0.2), value: phase)
    }

    // MARK: - Action button (Go / Continue)

    private func actionButton(size: CGSize) -> some View {
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
        .position(x: size.width * 0.5, y: size.height * 0.88)
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
                        popPlayer.play("popEffect.mp3", from: apiClient)
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
                        popPlayer.play("popEffect.mp3", from: apiClient)
                        handleInteraction()
                    },
                    showDebug: false
                )
            }
        default:
            EggHatchGame(size: size, onCrack: {
                popPlayer.play("eggCrack.mp3", from: apiClient)
            }, onHatch: {
                popPlayer.play("eggCrack.mp3", from: apiClient)
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

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalInteractions, id: \.self) { i in
                Circle()
                    .fill(i < interactionCount ? Color.bmConceptGreen : Color.bmNavy09)
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Narration

    private func startIntroNarration() {
        let text = "Let's make the *ssssss* sound!"
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
        let text = screen.displayText ?? "Say *ssssss* and play!"
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
        .frame(maxWidth: size.width * 0.8, maxHeight: size.height * 0.75)
        .position(x: size.width * 0.5, y: size.height * 0.52)
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
        "Level1_SnakeEgg_Whole.png",
        "Level1_SnakeEgg_Cracked.png",
        "Level1_SnakeEgg_Hatched.png"
    ]

    private func eggPosition(_ index: Int) -> CGPoint {
        let xPositions: [CGFloat] = [0.25, 0.50, 0.75]
        return CGPoint(x: size.width * xPositions[index], y: size.height * 0.52)
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
            .frame(maxWidth: size.width * 0.22, maxHeight: size.height * 0.55)
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
