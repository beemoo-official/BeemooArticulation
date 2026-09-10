import SwiftUI

/// Solid cream plate along the bottom of the screen for prompt text.
/// Navy ink, green marker word, minimum 96pt tall, full width.
struct PromptPlate: View {
    let text: String

    var body: some View {
        Text(MarkerParser.parse(text, font: .nunito(36, weight: .bold)))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 96)
            .padding(.vertical, 16)
            .background(Color.bmCream)
    }
}
