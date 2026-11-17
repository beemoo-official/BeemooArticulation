import SwiftUI

/// Clear Speech → "Pick a sound!" Each sound is a big chunky tile that opens its own world
/// (S → the jungle trail). Sounds that aren't built yet wiggle and say "Coming soon!".
struct SoundPickerView: View {
    @Binding var path: NavigationPath

    @Environment(SProgressStore.self) private var sProgress
    @State private var wiggling: String?

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 600
            ScrollView {
                VStack(spacing: wide ? 28 : 18) {
                    HStack {
                        ChunkyBackButton { path.removeLast() }
                        Spacer()
                    }

                    greeting(wide: wide)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: wide ? 24 : 16), count: wide ? 4 : 2),
                        spacing: wide ? 26 : 18
                    ) {
                        ForEach(SpeechSound.all) { sound in
                            SoundTile(
                                sound: sound,
                                wide: wide,
                                stars: sound.id == "s" ? sProgress.completedLevelCount : nil,
                                wiggle: wiggling == sound.id
                            ) { open(sound) }
                        }
                    }
                }
                .frame(maxWidth: 900)
                .padding(.horizontal, wide ? 32 : 18)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .background { SkyBackground() }
    }

    private func greeting(wide: Bool) -> some View {
        HStack(alignment: .center, spacing: 6) {
            RemoteImage(filename: "mascot/BEEMOO_03_Pointing.png")
                .scaledToFit()
                .frame(width: wide ? 150 : 104, height: wide ? 150 : 104)
            Text("Which sound do you want to play with?")
                .font(.baloo2(wide ? 30 : 21))
                .foregroundStyle(Color.bmNavy)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 22).fill(.white)
                        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                }
                .frame(maxWidth: wide ? 460 : .infinity, alignment: .leading)
            if wide { Spacer() }
        }
    }

    private func open(_ sound: SpeechSound) {
        if sound.isLive {
            if sound.id == "s" { path.append(Route.sPracticeHome) }
            return
        }
        withAnimation(.default) { wiggling = sound.id }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if wiggling == sound.id { withAnimation { wiggling = nil } }
        }
    }
}

// MARK: - Tile

private struct SoundTile: View {
    let sound: SpeechSound
    let wide: Bool
    /// Finished levels, shown on live sounds
    let stars: Int?
    let wiggle: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: wide ? 6 : 2) {
                picture
                Text(sound.letter)
                    .font(.baloo2(letterSize))
                    .foregroundStyle(.white)
                    .shadow(color: sound.side, radius: 0, y: 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    // Baloo's line box is much taller than its capitals
                    .frame(height: letterSize * 0.92)
                Text(wiggle ? "Coming soon!" : sound.world)
                    .font(.baloo2(wide ? 20 : 16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(sound.side.opacity(0.45)))
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, wide ? 20 : 14)
            .padding(.bottom, wide ? 18 : 14)
            .overlay(alignment: .topTrailing) { badge }
        }
        .buttonStyle(.chunky(sound.face, side: sound.side, radius: wide ? 34 : 28, depth: wide ? 10 : 8, rim: 4))
        .saturation(sound.isLive ? 1 : 0.8)
        .modifier(Shake(amount: wiggle ? 1 : 0))
        .accessibilityLabel(sound.isLive ? "\(sound.letter) sound, \(sound.world)" : "\(sound.letter) sound, coming soon")
    }

    private var letterSize: CGFloat {
        let base: CGFloat = wide ? 88 : 66
        return sound.letter.count > 1 ? base * 0.8 : base
    }

    @ViewBuilder
    private var picture: some View {
        let side: CGFloat = wide ? 80 : 56
        ZStack {
            Circle().fill(.white.opacity(0.28))
            if let art = sound.art {
                RemoteImage(filename: art)
                    .scaledToFit()
                    .padding(side * 0.08)
            } else {
                Text(sound.emoji).font(.system(size: side * 0.55))
            }
        }
        .frame(width: side, height: side)
    }

    @ViewBuilder
    private var badge: some View {
        if !sound.isLive {
            Image(systemName: "lock.fill")
                .font(.system(size: wide ? 18 : 14, weight: .bold))
                .foregroundStyle(sound.side)
                .frame(width: wide ? 38 : 30, height: wide ? 38 : 30)
                .background(Circle().fill(.white))
                .padding(10)
        } else if let stars, stars > 0 {
            HStack(spacing: 3) {
                Image(systemName: "star.fill").foregroundStyle(Color.bmYellow)
                Text("\(stars)")
            }
            .font(.baloo2(wide ? 18 : 15))
            .foregroundStyle(Color.bmNavy)
            .padding(.horizontal, 9)
            .padding(.vertical, 2)
            .background(Capsule().fill(.white))
            .padding(10)
        }
    }
}

/// Side-to-side wiggle for a locked tile
private struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(amount * .pi * 6), y: 0))
    }
}

// MARK: - Background

/// Bright sky with soft clouds and rolling hills: neutral ground before picking a world.
struct SkyBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: "6CC6F5"), Color(hex: "BFE9FF")], startPoint: .top, endPoint: .bottom)
                cloud(width: w * 0.42).position(x: w * 0.18, y: h * 0.14)
                cloud(width: w * 0.32).position(x: w * 0.82, y: h * 0.08)
                cloud(width: w * 0.28).position(x: w * 0.7, y: h * 0.42)
                hill(color: Color(hex: "8BD46A"), height: h * 0.22, bump: 0.3)
                hill(color: Color(hex: "6DBF4F"), height: h * 0.15, bump: 0.7)
            }
        }
        .ignoresSafeArea()
    }

    private func cloud(width: CGFloat) -> some View {
        ZStack {
            Capsule().frame(width: width, height: width * 0.32).offset(y: width * 0.08)
            Circle().frame(width: width * 0.42).offset(x: -width * 0.14, y: -width * 0.04)
            Circle().frame(width: width * 0.32).offset(x: width * 0.16, y: -width * 0.02)
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    private func hill(color: Color, height: CGFloat, bump: CGFloat) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: 0, y: h - height * 0.6))
                p.addQuadCurve(to: CGPoint(x: w, y: h - height * 0.5),
                               control: CGPoint(x: w * bump, y: h - height * 1.4))
                p.addLine(to: CGPoint(x: w, y: h))
                p.addLine(to: CGPoint(x: 0, y: h))
                p.closeSubpath()
            }
            .fill(color)
        }
    }
}
