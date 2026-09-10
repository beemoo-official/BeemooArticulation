import SwiftUI

struct CelebrationScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FFE07A"), Color(hex: "FFD100")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("You did it!")
                    .font(.baloo2(36))
                    .foregroundStyle(Color.bmNavy)

                if let audio = screen.audio {
                    Text(audio)
                        .font(.nunito(18))
                        .foregroundStyle(Color.bmNavy.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Text("Tap to finish")
                    .font(.nunito(14, weight: .bold))
                    .foregroundStyle(Color.bmNavy.opacity(0.4))
                    .padding(.top, 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
    }
}
