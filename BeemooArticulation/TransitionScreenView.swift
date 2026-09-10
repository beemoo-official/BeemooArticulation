import SwiftUI

struct TransitionScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    private var conceptParts: [String] {
        screen.concept.components(separatedBy: "/")
    }

    private var variantColors: [Color] {
        switch screen.variant ?? 0 {
        case 0: return [Color(hex: "2A7BD4"), Color(hex: "1E5FA8")]
        case 1: return [Color(hex: "8B57C4"), Color(hex: "6B3FA0")]
        default: return [Color(hex: "3E9B4F"), Color(hex: "2D7A3B")]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: variantColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Next up")
                    .font(.nunito(16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))

                HStack(spacing: 16) {
                    ForEach(conceptParts, id: \.self) { part in
                        Text(part)
                            .font(.baloo2(36))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
