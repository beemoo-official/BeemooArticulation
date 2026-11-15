import SwiftUI

struct ActivityRunnerView: View {
    let config: ActivityConfig
    let onDismiss: () -> Void
    @State private var vm: RunnerViewModel
    @Environment(APIClient.self) private var apiClient
    @Environment(TrialLogger.self) private var trialLogger
    @Environment(RunnerSettings.self) private var settings

    @State private var preloader = AssetPreloader()
    @State private var assetsReady = false

    init(config: ActivityConfig, onDismiss: @escaping () -> Void) {
        self.config = config
        self.onDismiss = onDismiss
        self._vm = State(initialValue: RunnerViewModel(config: config))
    }

    var body: some View {
        ZStack {
            if assetsReady {
                // Screen content
                screenView
                    .id(vm.currentScreen.n)
                    .transition(.opacity)
                    .animation(.easeOut(duration: BM.transitionDuration), value: vm.currentScreen.n)

                // Chrome overlay
                chromeOverlay
            } else {
                // Loading screen with progress
                AssetLoadingOverlay(
                    preloader: preloader,
                    activityTitle: config.title
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bmCream)
        .task {
            let paths = AssetPreloader.allAssetPaths(for: config)
            await preloader.preload(paths, from: apiClient)
            withAnimation(.easeOut(duration: 0.3)) {
                assetsReady = true
            }
        }
        .onChange(of: vm.isFinished) { _, finished in
            if finished { onDismiss() }
        }
    }

    // MARK: - Chrome

    private var chromeOverlay: some View {
        VStack {
            HStack {
                RunnerHomeButton(onExit: onDismiss)
                Spacer()
                ProgressPill(
                    current: vm.currentIndex + 1,
                    total: vm.screenCount
                )
            }
            .padding(.top, 14)
            .padding(.horizontal, 14)

            Spacer()

            HStack {
                Spacer()
                if !hidesNextButton {
                    NextButton { vm.advance() }
                }
            }
            .padding(.bottom, 14)
            .padding(.horizontal, 14)
        }
    }

    private var hidesNextButton: Bool {
        switch vm.currentScreen.type {
        case .receptive, .soundDiscrimination, .wordProduction, .sentenceProduction, .flashcard, .soundModeling, .monkeyClimb, .riverHop:
            true
        default:
            false
        }
    }

    // MARK: - Screen dispatch

    @ViewBuilder
    private var screenView: some View {
        let screen = vm.currentScreen
        switch screen.type {
        case .intro:
            IntroScreenView(screen: screen, settings: settings) { vm.advance() }
        case .teaching:
            TeachingScreenView(screen: screen, settings: settings) { vm.advance() }
        case .comparison:
            ComparisonScreenView(screen: screen, settings: settings) { vm.advance() }
        case .receptive:
            ReceptiveScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() }
            )
        case .transition:
            TransitionScreenView(screen: screen) { vm.advance() }
        case .celebration:
            CelebrationScreenView(screen: screen) { vm.advance() }
        case .soundModeling:
            SoundModelingScreenView(
                screen: screen,
                settings: settings,
                onAdvance: { vm.advance() },
                isFirstScreen: vm.currentIndex == 0
            )
        case .soundDiscrimination:
            SoundDiscriminationScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() },
                isFirstScreen: vm.currentIndex == 0
            )
        case .wordProduction:
            WordProductionScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() }
            )
        case .sentenceProduction:
            SentenceProductionScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() }
            )
        case .flashcard:
            FlashcardScreenView(screen: screen, settings: settings) { vm.advance() }
        case .monkeyClimb:
            MonkeyClimbScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() }
            )
        case .riverHop:
            RiverHopScreenView(
                screen: screen,
                activityId: config.activityId,
                settings: settings,
                trialLogger: trialLogger,
                onAdvance: { vm.advance() }
            )
        }
    }
}
