import SwiftUI

struct ActivityRunnerView: View {
    let config: ActivityConfig
    let onDismiss: () -> Void
    @State private var vm: RunnerViewModel

    init(config: ActivityConfig, onDismiss: @escaping () -> Void) {
        self.config = config
        self.onDismiss = onDismiss
        self._vm = State(initialValue: RunnerViewModel(config: config))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            screenView
                .id(vm.currentScreen.n)
                .transition(.opacity)
                .animation(.easeOut(duration: BM.transitionDuration), value: vm.currentScreen.n)

            HoldToExitButton { onDismiss() }
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .background(Color.bmCream)
        .ignoresSafeArea()
        .onAppear {
            OrientationHelper.lockLandscape()
        }
        .onDisappear {
            OrientationHelper.lockPortrait()
        }
        .onChange(of: vm.isFinished) { _, finished in
            if finished {
                onDismiss()
            }
        }
        .statusBarHidden()
    }

    // MARK: - Screen dispatch

    @ViewBuilder
    private var screenView: some View {
        let screen = vm.currentScreen
        switch screen.type {
        case .intro:
            IntroScreenView(screen: screen) { vm.advance() }
        case .teaching:
            TeachingScreenView(screen: screen) { vm.advance() }
        case .comparison:
            PlaceholderScreenView(screen: screen, label: "Comparison") { vm.advance() }
        case .receptive:
            PlaceholderScreenView(screen: screen, label: "Receptive") { vm.advance() }
        case .transition:
            TransitionScreenView(screen: screen) { vm.advance() }
        case .celebration:
            CelebrationScreenView(screen: screen) { vm.advance() }
        }
    }
}

// MARK: - Hold-to-exit button

/// Adult-targeted close control. First tap reveals the "Hold to exit" label and a ring
/// that fills over the hold duration. A full hold dismisses the runner.
struct HoldToExitButton: View {
    let onExit: () -> Void

    private let holdDuration: Double = 1.0
    private let ringSize: CGFloat = 32

    @State private var revealed = false
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 8) {
            if revealed {
                Text("Hold to exit")
                    .font(.nunito(12, weight: .bold))
                    .foregroundStyle(Color.bmNavy50)
                    .transition(.opacity)
            }

            ZStack {
                Circle()
                    .fill(.black.opacity(0.15))
                    .frame(width: ringSize, height: ringSize)

                // Progress ring
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(Color.bmNavy, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.bmNavy.opacity(0.6))
            }
        }
        .onTapGesture {
            if !revealed {
                withAnimation(.easeOut(duration: 0.2)) { revealed = true }
                scheduleHide()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard revealed, !isHolding else { return }
                    isHolding = true
                    hideTask?.cancel()
                    withAnimation(.linear(duration: holdDuration)) {
                        holdProgress = 1.0
                    }
                }
                .onEnded { _ in
                    if holdProgress >= 0.99 {
                        onExit()
                    } else {
                        isHolding = false
                        withAnimation(.easeOut(duration: 0.15)) {
                            holdProgress = 0
                        }
                        scheduleHide()
                    }
                }
        )
        .onChange(of: holdProgress) { _, newValue in
            if newValue >= 0.99 && isHolding {
                onExit()
            }
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                revealed = false
                holdProgress = 0
            }
        }
    }
}

// MARK: - Placeholder for unimplemented screen types

struct PlaceholderScreenView: View {
    let screen: ScreenConfig
    let label: String
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            Color.bmCream
            VStack(spacing: 16) {
                Text(label)
                    .font(.baloo2(28))
                    .foregroundStyle(Color.bmNavy)
                Text("Screen \(screen.n) — \(screen.concept)")
                    .font(.nunito(16))
                    .foregroundStyle(Color.bmNavy62)
                Text("Tap to continue")
                    .font(.nunito(13))
                    .foregroundStyle(Color.bmNavy50)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
