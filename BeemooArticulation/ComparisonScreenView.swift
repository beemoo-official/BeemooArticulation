import SwiftUI

struct ComparisonScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var currentLineIndex: Int = 0
    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    private var lines: [String] { screen.lines ?? [] }
    private var cues: [Int] { screen.cuesXPercent ?? [] }
    private var labels: [String]? { screen.labels }
    private var cueTopPercent: Int { screen.cueTopPercent ?? 50 }
    private var isLastLine: Bool { currentLineIndex >= lines.count - 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let sceneName = screen.sceneName {
                    SceneContainer(sceneName: sceneName) { imageRect in
                        cueOverlays(in: imageRect)
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
        .onTapGesture { advanceLine() }
        .onAppear { startCurrentLine() }
        .onDisappear { narrationTrack.stop() }
    }

    private func startCurrentLine() {
        guard currentLineIndex < lines.count else { return }
        let text = lines[currentLineIndex]
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }

    private func advanceLine() {
        narrationTrack.stop()
        if isLastLine {
            onAdvance()
        } else {
            currentLineIndex += 1
            startCurrentLine()
        }
    }

    @ViewBuilder
    private func cueOverlays(in imageRect: CGRect) -> some View {
        if currentLineIndex < cues.count {
            let cx = imageRect.minX + imageRect.width * CGFloat(cues[currentLineIndex]) / 100
            let cy = imageRect.minY + imageRect.height * CGFloat(cueTopPercent) / 100
            let shorterSide = min(imageRect.width, imageRect.height)
            let pointerSize = shorterSide * 0.18

            Circle()
                .stroke(Color.bmRingOrange, lineWidth: 3)
                .frame(width: pointerSize, height: pointerSize)
                .position(x: cx, y: cy)
        }

        if let labels = labels {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index < cues.count {
                    let lx = imageRect.minX + imageRect.width * CGFloat(cues[index]) / 100

                    Text(label)
                        .font(.nunito(14, weight: .bold))
                        .foregroundStyle(Color.bmNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.bmCream.opacity(0.9)))
                        .position(x: lx, y: imageRect.maxY - 16)
                }
            }
        }
    }
}
