import SwiftUI

/// Shown on app launch until the backend is reachable and the app is ready.
struct SplashScreen: View {
    let status: String
    @State private var dotScale: CGFloat = 0.6

    var body: some View {
        ZStack {
            Color.bmCream.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("beemoo_fly")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("BEEMOO")
                    .font(.baloo2(32))
                    .foregroundStyle(Color.bmNavy)

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.bmYellow)
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotScale)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: dotScale
                            )
                    }
                }
                .onAppear { dotScale = 1.0 }

                // Status text
                Text(status)
                    .font(.nunito(14))
                    .foregroundStyle(Color.bmNavy62)
                    .animation(.easeOut(duration: 0.2), value: status)
            }
        }
    }
}
