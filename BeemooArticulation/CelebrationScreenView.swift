import SwiftUI

struct CelebrationScreenView: View {
    let screen: ScreenConfig
    let onAdvance: () -> Void
    @State private var bobOffset: CGFloat = 0

    private let heroGradient = LinearGradient(
        colors: [Color(hex: "FFF6DA"), Color(hex: "FFEFB8"), Color(hex: "FFE07A")],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            heroGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Image("star")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(y: bobOffset)

                Text("You did it!")
                    .font(.baloo2(44))
                    .foregroundStyle(Color.bmNavy)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onAdvance() }
        .onAppear {
            withAnimation(.bmBob) {
                bobOffset = -8
            }
        }
    }
}
