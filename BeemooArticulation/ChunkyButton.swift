import SwiftUI
import UIKit

/// A toy-like 3D button: a colored face sitting on a darker "side". Pressing pushes the face
/// down onto its side (and gives a light tap of haptics), like pressing a real plastic key.
struct ChunkyButtonStyle<S: InsettableShape>: ButtonStyle {
    let shape: S
    let face: Color
    let side: Color
    var depth: CGFloat = 6
    /// White rim around the face, like a sticker edge
    var rim: CGFloat = 0

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .background { shape.fill(face) }
            .overlay { if rim > 0 { shape.strokeBorder(.white, lineWidth: rim) } }
            .offset(y: pressed ? depth : 0)
            .background {
                shape.fill(side)
                    .offset(y: depth)
                    .shadow(color: .black.opacity(pressed ? 0.12 : 0.22), radius: pressed ? 2 : 6, y: pressed ? 2 : 6)
            }
            .padding(.bottom, depth)
            .animation(.spring(duration: 0.18, bounce: 0.35), value: pressed)
            .onChange(of: pressed) { _, isDown in
                if isDown { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            }
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle<RoundedRectangle> {
    static func chunky(_ face: Color, side: Color, radius: CGFloat = 24, depth: CGFloat = 6, rim: CGFloat = 0) -> Self {
        ChunkyButtonStyle(shape: RoundedRectangle(cornerRadius: radius), face: face, side: side, depth: depth, rim: rim)
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle<Circle> {
    static func chunkyCircle(_ face: Color, side: Color, depth: CGFloat = 6, rim: CGFloat = 0) -> Self {
        ChunkyButtonStyle(shape: Circle(), face: face, side: side, depth: depth, rim: rim)
    }
}

/// Round white back button in the chunky style, for the kid-facing screens.
struct ChunkyBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Color.bmNavy)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.chunkyCircle(.white, side: Color(hex: "C9D3E0"), depth: 4))
        .accessibilityLabel("Back")
    }
}
