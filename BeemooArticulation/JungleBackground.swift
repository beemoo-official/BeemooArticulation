import SwiftUI

/// Full-bleed jungle background for S sound activity screens.
/// Fills the entire screen while preserving aspect ratio — crops edges if needed.
struct JungleBackground: View {
    var body: some View {
        GeometryReader { geo in
            RemoteImage(filename: "Jungle_Background.png")
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
