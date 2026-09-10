import SwiftUI

struct ComparisonScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    @State private var currentLineIndex: Int = 0

    private var lines: [String] { screen.lines ?? [] }
    private var cues: [Int] { screen.cuesXPercent ?? [] }
    private var labels: [String]? { screen.labels }
    private var cueTopPercent: Int { screen.cueTopPercent ?? 50 }

    private var isLastLine: Bool {
        currentLineIndex >= lines.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Scene with cue overlays
            if let sceneName = screen.sceneName {
                SceneContainer(sceneName: sceneName) { imageRect in
                    cueOverlays(in: imageRect)
                }
            } else {
                Color.bmCream
            }

            // Current line in the prompt plate
            if currentLineIndex < lines.count {
                PromptPlate(text: lines[currentLineIndex])
            }
        }
        .background(Color.bmCream)
        .contentShape(Rectangle())
        .onTapGesture {
            if isLastLine {
                onAdvance()
            } else {
                currentLineIndex += 1
            }
        }
    }

    // MARK: - Cue pointer overlays

    @ViewBuilder
    private func cueOverlays(in imageRect: CGRect) -> some View {
        // Show a cue pointer for the current line
        if currentLineIndex < cues.count {
            let cx = imageRect.minX + imageRect.width * CGFloat(cues[currentLineIndex]) / 100
            let cy = imageRect.minY + imageRect.height * CGFloat(cueTopPercent) / 100
            let shorterSide = min(imageRect.width, imageRect.height)
            let pointerSize = shorterSide * 0.18

            // Pointer: stroked circle with a small downward triangle
            Circle()
                .stroke(Color.bmRingOrange, lineWidth: 3)
                .frame(width: pointerSize, height: pointerSize)
                .position(x: cx, y: cy)
        }

        // Optional labels under each region
        if let labels = labels {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index < cues.count {
                    let lx = imageRect.minX + imageRect.width * CGFloat(cues[index]) / 100

                    Text(label)
                        .font(.nunito(14, weight: .bold))
                        .foregroundStyle(Color.bmNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.bmCream.opacity(0.9))
                        )
                        .position(x: lx, y: imageRect.maxY - 16)
                }
            }
        }
    }
}
