import SwiftUI

struct ActivityRunnerView: View {
    let config: ActivityConfig
    let onDismiss: () -> Void
    @State private var vm: RunnerViewModel
    @State private var showCloseConfirm = false

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

            closeControl
                .padding(.top, 12)
                .padding(.trailing, 16)
        }
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            OrientationHelper.lockLandscape()
        }
        .onDisappear {
            OrientationHelper.lockPortrait()
        }
        .background {
            OrientationLockView(orientations: .landscape)
                .frame(width: 0, height: 0)
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

    // MARK: - Close control (adult-targeted, press-and-hold)

    private var closeControl: some View {
        Button(action: {}) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 30, height: 30)
                .background(Circle().fill(.black.opacity(0.3)))
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onDismiss()
                }
        )
    }
}

// MARK: - Placeholder for unimplemented screen types

struct PlaceholderScreenView: View {
    let screen: ScreenConfig
    let label: String
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                Text(label)
                    .font(.baloo2(28))
                    .foregroundStyle(.white)
                Text("Screen \(screen.n) — \(screen.concept)")
                    .font(.nunito(16))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Tap to continue")
                    .font(.nunito(13))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
