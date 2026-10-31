import SwiftUI

struct IntroScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var bubbleVM: NarratedBubbleVM
    @State private var narrationTrack: SystemNarrationTrack = SystemNarrationTrack()
    @State private var hasAppeared = false

    init(screen: ScreenConfig, settings: RunnerSettings, onAdvance: @escaping () -> Void) {
        self.screen = screen
        self.settings = settings
        self.onAdvance = onAdvance
        // Create VM immediately so the bubble exists from first render
        self._bubbleVM = State(initialValue: NarratedBubbleVM(
            markerText: screen.displayText ?? "",
            narrationTrack: SystemNarrationTrack()
        ))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if let sceneName = screen.sceneName {
                    SceneContainer(sceneName: sceneName) { _ in }
                } else {
                    Color.bmCream
                }

                NarratedBubble(vm: bubbleVM, contentWidth: geo.size.width * 0.6)
                    .padding(.top, 60)
            }
        }
        .background(Color.bmCream)
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            // Small delay so the layout settles before narration starts
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                bubbleVM.isNarrationOff = !settings.narrationEnabled
                bubbleVM.startNarration()
            }
        }
        .onDisappear { narrationTrack.stop() }
    }
}
