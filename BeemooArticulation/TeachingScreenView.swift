import SwiftUI

struct TeachingScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let sceneName = screen.sceneName {
                    SceneContainer(sceneName: sceneName) { imageRect in
                        highlightRing(in: imageRect)
                    }
                } else {
                    Color.bmCream
                }

                if let vm = bubbleVM {
                    NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.6)
                        .padding(.top, 60)
                        .padding(.leading, 70)
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

    @ViewBuilder
    private func highlightRing(in imageRect: CGRect) -> some View {
        if let ringX = screen.ringXPercent {
            let ringY = screen.ringYPercent ?? 50
            let cx = imageRect.minX + imageRect.width * CGFloat(ringX) / 100
            let cy = imageRect.minY + imageRect.height * CGFloat(ringY) / 100
            let shorterSide = min(imageRect.width, imageRect.height)
            let ringSize = shorterSide * 0.22

            Circle()
                .stroke(Color.bmRingOrange, lineWidth: 4)
                .frame(width: ringSize, height: ringSize)
                .position(x: cx, y: cy)
        }
    }
}
