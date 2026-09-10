import SwiftUI

struct IntroScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Scene fills all space above the prompt plate
            if let sceneName = screen.sceneName {
                SceneContainer(sceneName: sceneName) { _ in }
            } else {
                Color.bmCream
            }

            // Prompt plate pinned to bottom
            if let text = screen.displayText {
                PromptPlate(text: text)
            }
        }
        .background(Color.bmCream)
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
