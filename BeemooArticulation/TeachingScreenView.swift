import SwiftUI

struct TeachingScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            if let sceneName = screen.sceneName {
                SceneContainer(sceneName: sceneName) { imageRect in
                    highlightRing(in: imageRect)
                }
                .ignoresSafeArea()
            } else {
                Color.bmCream.ignoresSafeArea()
            }

            if let text = screen.displayText {
                PromptPlate(text: text)
            }
        }
        .background(Color.bmCream)
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
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
