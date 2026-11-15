import SwiftUI

/// A 3D-style wooden card frame drawn with SwiftUI gradients.
/// Thick rounded border with depth shading to look like the reference design.
struct CardFrame: View {
    var cornerRadius: CGFloat = 20
    var borderWidth: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(hex: "D4881F"),  // dark golden
                        Color(hex: "F0A830"),  // bright golden
                        Color(hex: "E89520"),  // mid golden
                        Color(hex: "C47818"),  // shadow
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: borderWidth
            )
            .shadow(color: Color(hex: "8B5E1C").opacity(0.4), radius: 2, x: 0, y: 2)
            .allowsHitTesting(false)
    }
}
