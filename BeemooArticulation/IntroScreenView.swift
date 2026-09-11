import SwiftUI

struct IntroScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack: SystemNarrationTrack = SystemNarrationTrack()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if let sceneName = screen.sceneName {
                    SceneContainer(sceneName: sceneName) { _ in }
                } else {
                    Color.bmCream
                }

                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.6)
                        .padding(.top, 60)
                }
            }
        }
        .background(Color.bmCream)
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
    }

    private func startNarration() {
        guard let text = screen.displayText else { return }
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }
}
