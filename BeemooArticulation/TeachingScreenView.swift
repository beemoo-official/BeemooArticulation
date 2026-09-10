import SwiftUI

struct TeachingScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            // Full-bleed scene
            if let sceneName = screen.sceneName {
                Image(sceneName)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            // Highlight ring
            if let ringX = screen.ringXPercent {
                GeometryReader { geo in
                    let cx = geo.size.width * CGFloat(ringX) / 100
                    let cy = geo.size.height / 2
                    Circle()
                        .stroke(Color.bmYellow, lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .position(x: cx, y: cy)
                }
                .ignoresSafeArea()
            }

            // Scrim for text
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .ignoresSafeArea()

            // Prompt text
            VStack {
                Spacer()
                if let text = screen.displayText {
                    Text(MarkerParser.parse(text, font: .nunito(26, weight: .bold)))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
