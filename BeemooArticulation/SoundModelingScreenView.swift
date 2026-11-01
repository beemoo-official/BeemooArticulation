import SwiftUI

/// Level 1 — Make the S Sound.
/// Three game variants: spot tap (0), snake drag (1), egg hatch (2).
/// Each interaction is a production opportunity for sustained /s/.
struct SoundModelingScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @Environment(APIClient.self) private var apiClient

    @State private var interactionCount = 0
    @State private var completedSpots: Set<String> = []
    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()
    @State private var popPlayer = RemoteAudioPlayer()

    private let maxInteractions = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Game area
                gameContent(size: geo.size)

                // BEEMOO speech bubble
                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.5)
                        .padding(.top, 60)
                        .padding(.leading, 70)
                }

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
        .background { JungleBackground() }
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
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
                onAdvance()
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
            return 3  // 3 eggs to hatch
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

    private func startNarration() {
        let text = screen.displayText ?? "Let's make the *ssssss* sound!"
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
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

    // Per-egg state: 0 = whole, 1 = cracked, 2 = hatched
    @State private var eggStates: [Int] = [0, 0, 0]
    @State private var eggScales: [CGFloat] = [1, 1, 1]

    private let eggFilenames = [
        "Level1_SnakeEgg_Whole.png",
        "Level1_SnakeEgg_Cracked.png",
        "Level1_SnakeEgg_Hatched.png"
    ]

    // Egg positions spread horizontally
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

                // Bounce
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
