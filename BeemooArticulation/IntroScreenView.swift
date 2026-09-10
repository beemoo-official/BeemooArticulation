import SwiftUI

struct IntroScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scene fills the full area; plate overlays bottom
            if let sceneName = screen.sceneName {
                SceneContainer(sceneName: sceneName) { _ in }
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
}
