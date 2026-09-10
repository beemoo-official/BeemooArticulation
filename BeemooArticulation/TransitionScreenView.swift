import SwiftUI

struct TransitionScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    private var variantColor: Color {
        switch screen.variant ?? 0 {
        case 0: Color(hex: "2A7BD4")
        case 1: Color(hex: "8B57C4")
        default: Color(hex: "3E9B4F")
        }
    }

    /// Splits "MORE/LESS" into ["MORE", "/", "LESS"] so the slash can be styled independently.
    private var conceptTokens: [(String, Bool)] {
        let raw = screen.concept
        var tokens: [(String, Bool)] = []
        for part in raw.components(separatedBy: "/") {
            if !tokens.isEmpty {
                tokens.append(("/", true))
            }
            tokens.append((part, false))
        }
        return tokens
    }

    var body: some View {
        ZStack {
            variantColor.ignoresSafeArea()

            HStack(spacing: 4) {
                ForEach(Array(conceptTokens.enumerated()), id: \.offset) { _, token in
                    Text(token.0)
                        .font(.baloo2(56))
                        .foregroundStyle(.white.opacity(token.1 ? 0.4 : 1.0))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
        .task {
            try? await Task.sleep(for: .milliseconds(1200))
            onAdvance()
        }
    }
}
