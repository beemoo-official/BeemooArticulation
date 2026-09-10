import SwiftUI

struct IntroScreenView: View {
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

            // Scrim for text legibility
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Prompt text overlay
            VStack {
                Spacer()
                if let text = screen.displayText {
                    Text(MarkerParser.parse(text, font: .nunito(28, weight: .bold)))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
