import SwiftUI

/// Level 1 — Make the S Sound.
/// Three game variants: spot tap (0), snake drag (1), egg hatch (2).
/// Each interaction is a production opportunity for sustained /s/.
struct SoundModelingScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var interactionCount = 0
    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    private let maxInteractions = 10

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
        .background(Color.bmCream)
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Game variants

    @ViewBuilder
    private func gameContent(size: CGSize) -> some View {
        let variant = screen.variant ?? 0
        switch variant {
        case 0:
            SpotTapGame(
                size: size,
                spotX: screen.spotXPercent ?? 50,
                spotY: screen.spotYPercent ?? 50,
                onTap: handleInteraction
            )
        case 1:
            SnakeDragGame(size: size, onDrop: handleInteraction)
        default:
            EggHatchGame(size: size, onTap: handleInteraction)
        }
    }

    // MARK: - Interaction handling

    private func handleInteraction() {
        interactionCount += 1
        if interactionCount >= maxInteractions {
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                onAdvance()
            }
        }
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<maxInteractions, id: \.self) { i in
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
    let spotX: Int
    let spotY: Int
    let onTap: () -> Void

    @State private var spotScale: CGFloat = 1.0
    @State private var showRipple = false

    var body: some View {
        ZStack {
            // Snake background
            RemoteImage(filename: "Level1_SnakePit_Teal_Snake.png")
                .scaledToFit()
                .frame(maxWidth: size.width * 0.5, maxHeight: size.height * 0.7)
                .position(x: size.width * 0.5, y: size.height * 0.5)

            // Pulsing spot
            ZStack {
                if showRipple {
                    Circle()
                        .stroke(Color.bmConceptGreen.opacity(0.4), lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(showRipple ? 1.6 : 1.0)
                        .opacity(showRipple ? 0 : 1)
                }
                Circle()
                    .fill(Color.bmConceptGreen.opacity(0.7))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.bmConceptGreen, lineWidth: 3)
                    )
                    .scaleEffect(spotScale)
            }
            .position(
                x: size.width * CGFloat(spotX) / 100,
                y: size.height * CGFloat(spotY) / 100
            )
            .onTapGesture {
                withAnimation(.spring(duration: 0.3)) {
                    spotScale = 1.3
                    showRipple = true
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation(.spring(duration: 0.3)) {
                        spotScale = 1.0
                        showRipple = false
                    }
                }
                onTap()
            }
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: spotScale
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    spotScale = 1.1
                }
            }
        }
    }
}

// MARK: - Snake Drag Game (variant 1)

private struct SnakeDragGame: View {
    let size: CGSize
    let onDrop: () -> Void

    @State private var snakeOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var snakeDropped = false
    @State private var currentSnake = 0

    private let snakeFilenames = [
        "Level1_SnakePit_Teal_Snake.png",
        "Level1_SnakePit_Green_Snake.png",
        "Level1_SnakePit_Orange_Snake.png",
        "Level1_SnakePit_Blue_Snake.png"
    ]

    var body: some View {
        ZStack {
            // Stone pit (drop target)
            RemoteImage(filename: "Level1_SnakePit_Stone_Pit.png")
                .scaledToFit()
                .frame(maxWidth: size.width * 0.35, maxHeight: size.height * 0.5)
                .position(x: size.width * 0.7, y: size.height * 0.55)

            // Draggable snake
            if !snakeDropped {
                RemoteImage(filename: snakeFilenames[currentSnake % snakeFilenames.count])
                    .scaledToFit()
                    .frame(maxWidth: size.width * 0.22, maxHeight: size.height * 0.4)
                    .offset(snakeOffset)
                    .position(x: size.width * 0.25, y: size.height * 0.5)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                snakeOffset = value.translation
                            }
                            .onEnded { value in
                                isDragging = false
                                let dropX = size.width * 0.25 + value.translation.width
                                let dropY = size.height * 0.5 + value.translation.height
                                let targetX = size.width * 0.7
                                let targetY = size.height * 0.55
                                let distance = hypot(dropX - targetX, dropY - targetY)

                                if distance < size.width * 0.18 {
                                    // Successful drop
                                    withAnimation(.spring(duration: 0.3)) {
                                        snakeDropped = true
                                    }
                                    onDrop()
                                    Task {
                                        try? await Task.sleep(for: .milliseconds(700))
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            snakeDropped = false
                                            snakeOffset = .zero
                                            currentSnake += 1
                                        }
                                    }
                                } else {
                                    withAnimation(.spring(duration: 0.4)) {
                                        snakeOffset = .zero
                                    }
                                }
                            }
                    )
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .animation(.spring(duration: 0.2), value: isDragging)
            }
        }
    }
}

// MARK: - Egg Hatch Game (variant 2)

private struct EggHatchGame: View {
    let size: CGSize
    let onTap: () -> Void

    @State private var eggState = 0 // 0 = whole, 1 = cracked, 2 = hatched
    @State private var eggScale: CGFloat = 1.0
    @State private var cycleCount = 0

    private let eggFilenames = [
        "Level1_SnakeEgg_Whole.png",
        "Level1_SnakeEgg_Cracked.png",
        "Level1_SnakeEgg_Hatched.png"
    ]

    var body: some View {
        RemoteImage(filename: eggFilenames[eggState])
            .scaledToFit()
            .frame(maxWidth: size.width * 0.3, maxHeight: size.height * 0.5)
            .scaleEffect(eggScale)
            .position(x: size.width * 0.5, y: size.height * 0.5)
            .onTapGesture {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                    eggScale = 1.15
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    withAnimation(.spring(duration: 0.3)) {
                        eggScale = 1.0
                        eggState = min(eggState + 1, 2)
                    }
                }
                onTap()

                // Reset egg after hatched
                if eggState == 2 {
                    Task {
                        try? await Task.sleep(for: .milliseconds(900))
                        withAnimation(.easeOut(duration: 0.3)) {
                            eggState = 0
                            cycleCount += 1
                        }
                    }
                }
            }
    }
}
