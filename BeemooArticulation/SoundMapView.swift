import SwiftUI

/// The S sound's world: a winding jungle trail with one stop per level, from the bottom up.
/// Finished stops show their stars, BEEMOO hovers over the stop to play next, and the big
/// Play button starts it. Every stop stays tappable so an adult can pick any level.
struct SoundMapView: View {
    let onDismiss: () -> Void

    @Environment(APIClient.self) private var apiClient
    @Environment(TrialLogger.self) private var trialLogger
    @Environment(RunnerSettings.self) private var runnerSettings
    @Environment(SProgressStore.self) private var progressStore

    static let levels: [TrailStop] = [
        TrailStop(level: 1, name: "Make the S Sound", friend: .art("s-sound/level1/BEEMOO_S_Sound_Snake.png")),
        TrailStop(level: 2, name: "Hear the S Sound", friend: .emoji("🦜")),
        TrailStop(level: 3, name: "Beginning S Words", friend: .art("s-sound/level3/elephant_stand.png")),
        TrailStop(level: 4, name: "Final S Words", friend: .art("s-sound/level1/monkey_crouch.png")),
        TrailStop(level: 5, name: "Middle S Words", friend: .emoji("🦥")),
        TrailStop(level: 6, name: "Beginning S Sentences", friend: .emoji("🦋")),
        TrailStop(level: 7, name: "Final S Sentences", friend: .emoji("🐸")),
        TrailStop(level: 8, name: "Middle S Sentences", friend: .emoji("🐯")),
    ]

    private var current: Int { min(progressStore.highestUnlockedLevel, Self.levels.count) }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > 600
            let layout = TrailLayout(width: geo.size.width, wide: wide, count: Self.levels.count)
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        trail(layout)
                            .frame(width: layout.width, height: layout.height)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollIndicators(.hidden)
                    .defaultScrollAnchor(.bottom)
                    .onAppear {
                        proxy.scrollTo("stop-\(current)", anchor: .center)
                    }
                }

                VStack {
                    header(wide: wide)
                        // Fade the trail out under the header so it never fights the buttons
                        .background(alignment: .top) {
                            LinearGradient(colors: [Color(hex: "1F6B33"), Color(hex: "1F6B33").opacity(0)], startPoint: .top, endPoint: .bottom)
                                .frame(height: wide ? 170 : 140)
                                .padding(.horizontal, wide ? -28 : -16)
                                .offset(y: -70)
                                .ignoresSafeArea()
                        }
                    Spacer()
                    playButton(wide: wide)
                }
                .padding(.horizontal, wide ? 28 : 16)
                .padding(.bottom, wide ? 24 : 12)
            }
        }
        .background { JungleTrailBackground() }
    }

    // MARK: - Trail

    private func trail(_ layout: TrailLayout) -> some View {
        ZStack {
            TrailPath(points: layout.pathPoints)
                .stroke(Color(hex: "7A4E24"), style: StrokeStyle(lineWidth: layout.pathWidth + 8, lineCap: .round, lineJoin: .round))
            TrailPath(points: layout.pathPoints)
                .stroke(Color(hex: "E8C383"), style: StrokeStyle(lineWidth: layout.pathWidth, lineCap: .round, lineJoin: .round))
            TrailPath(points: layout.pathPoints)
                .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 14]))

            JunglePlants(layout: layout)

            // The finish: a trophy at the top of the trail
            Text("🏆")
                .font(.system(size: layout.nodeSize * 0.8))
                .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
                .position(layout.finish)

            ForEach(Self.levels) { stop in
                friend(stop, layout: layout)
                stopButton(stop, layout: layout)
                    .position(layout.center(stop.level))
                    .id("stop-\(stop.level)")
            }

            if let here = Self.levels.first(where: { $0.level == current }) {
                HoveringBeemoo(size: layout.nodeSize * 0.95)
                    .position(x: layout.center(here.level).x + layout.towardMiddle(here.level) * layout.nodeSize * 0.15,
                              y: layout.center(here.level).y - layout.nodeSize * 1.05)
                    .allowsHitTesting(false)
            }
        }
    }

    private func stopButton(_ stop: TrailStop, layout: TrailLayout) -> some View {
        let done = progressStore.levelAccuracy[stop.level] != nil
        let isCurrent = stop.level == current
        let face = isCurrent ? Color(hex: "FFC928") : (done ? Color(hex: "3EAA4F") : Color(hex: "D6EFC8"))
        let side = isCurrent ? Color(hex: "C98F00") : (done ? Color(hex: "23753A") : Color(hex: "8DB57F"))
        let size = layout.nodeSize

        return VStack(spacing: 4) {
            Button { launchLevel(stop.level) } label: {
                Text("\(stop.level)")
                    .font(.baloo2(size * 0.46))
                    .foregroundStyle(isCurrent || done ? .white : Color(hex: "5E8A52"))
                    .shadow(color: side.opacity(isCurrent || done ? 1 : 0), radius: 0, y: 3)
                    .frame(width: size, height: size)
            }
            .buttonStyle(.chunkyCircle(face, side: side, depth: size * 0.09, rim: size * 0.05))
            .background { if isCurrent { PulseRing(color: Color(hex: "FFE680"), size: size) } }
            .accessibilityLabel("Level \(stop.level), \(stop.name)")

            StarRow(stars: stars(for: stop.level), size: size * 0.22)

            Text(stop.name)
                .font(.baloo2(layout.wide ? 16 : 13))
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color(hex: "7A4E24")))
                .overlay { Capsule().stroke(Color(hex: "A8713A"), lineWidth: 2) }
        }
        // Keep the node itself on the trail; the stars and sign hang below it
        .offset(y: layout.nodeSize * 0.42)
    }

    @ViewBuilder
    private func friend(_ stop: TrailStop, layout: TrailLayout) -> some View {
        let size = layout.nodeSize * 1.0
        let c = layout.center(stop.level)
        Group {
            switch stop.friend {
            case .art(let file):
                RemoteImage(filename: file).scaledToFit()
            case .emoji(let e):
                Text(e).font(.system(size: size * 0.7))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 3, y: 3)
        .position(x: c.x + layout.towardMiddle(stop.level) * layout.nodeSize * 1.35, y: c.y - layout.nodeSize * 0.1)
        .allowsHitTesting(false)
    }

    private func stars(for level: Int) -> Int {
        guard let accuracy = progressStore.levelAccuracy[level] else { return 0 }
        return accuracy >= 0.9 ? 3 : accuracy >= 0.7 ? 2 : 1
    }

    // MARK: - Header + Play

    private func header(wide: Bool) -> some View {
        HStack(spacing: 12) {
            ChunkyBackButton(action: onDismiss)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Text("S")
                    .font(.baloo2(wide ? 30 : 24))
                    .foregroundStyle(Color(hex: "23753A"))
                    .frame(width: wide ? 46 : 38, height: wide ? 46 : 38)
                    .background(Circle().fill(.white))
                Text("Jungle Trail")
                    .font(.baloo2(wide ? 28 : 21))
                    .foregroundStyle(.white)
                    .fixedSize()
            }
            .padding(.leading, 6)
            .padding(.trailing, 16)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(hex: "23753A")))
            .overlay { Capsule().stroke(.white, lineWidth: 3) }
            .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
            Spacer(minLength: 0)
            Button { launchFlashcards() } label: {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
            }
            .buttonStyle(.chunkyCircle(Color.bmBlue, side: Color.bmBlueDark, depth: 4, rim: 3))
            .accessibilityLabel("Flashcards")
        }
    }

    private func playButton(wide: Bool) -> some View {
        let stop = Self.levels[current - 1]
        return Button { launchLevel(stop.level) } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: wide ? 30 : 24, weight: .heavy))
                VStack(alignment: .leading, spacing: -4) {
                    Text("Play!")
                        .font(.baloo2(wide ? 34 : 28))
                    Text(stop.name)
                        .font(.baloo2(wide ? 17 : 14))
                        .opacity(0.85)
                }
            }
            .foregroundStyle(Color(hex: "6B4500"))
            .padding(.horizontal, wide ? 40 : 30)
            .padding(.vertical, wide ? 12 : 8)
        }
        .buttonStyle(.chunky(Color(hex: "FFC928"), side: Color(hex: "C98F00"), radius: 40, depth: 8, rim: 4))
    }

    // MARK: - Launch

    private func launchLevel(_ level: Int) {
        let activityId = "s-sound-level-\(level)"
        let config = SeedData.loadActivityConfig(activityId)
        let runner = ActivityRunnerView(config: config) { [self] in
            // Score this run from the trials it logged
            let trials = trialLogger.records().filter { $0.activityId == activityId }
            let firstAttemptCorrect = trials.filter { $0.firstAttemptOutcome == "correct" }.count
            progressStore.recordLevelCompletion(
                level: level,
                correctFirstAttempts: firstAttemptCorrect,
                totalTrials: trials.count,
                trialThreshold: runnerSettings.trialThreshold,
                accuracyThreshold: runnerSettings.accuracyThreshold
            )
            LandscapePresenter.dismiss()
        }
        .environment(apiClient)
        .environment(trialLogger)
        .environment(runnerSettings)
        .environment(progressStore)
        LandscapePresenter.present(runner)
    }

    private func launchFlashcards() {
        let config = SeedData.loadActivityConfig("s-sound-flashcards")
        let runner = ActivityRunnerView(config: config) {
            LandscapePresenter.dismiss()
        }
        .environment(apiClient)
        .environment(trialLogger)
        .environment(runnerSettings)
        .environment(progressStore)
        LandscapePresenter.present(runner)
    }
}

// MARK: - Model

struct TrailStop: Identifiable {
    enum Friend { case art(String), emoji(String) }
    let level: Int
    let name: String
    /// The jungle animal waiting beside this stop (art from the level's game where there is some)
    let friend: Friend
    var id: Int { level }
}

// MARK: - Layout

/// Stops zig-zag up the screen, level 1 at the bottom. Room is left at the top for the header
/// and at the bottom for the Play button.
struct TrailLayout {
    let width: CGFloat
    let wide: Bool
    let count: Int

    /// The trail keeps to a centered band; the jungle fills whatever is left on either side
    private var band: CGFloat { min(width, 640) }
    private var bandLeft: CGFloat { (width - band) / 2 }

    var nodeSize: CGFloat { wide ? 104 : 82 }
    var spacing: CGFloat { wide ? 190 : 165 }
    var pathWidth: CGFloat { wide ? 40 : 32 }
    private var topRoom: CGFloat { wide ? 230 : 190 }
    private var bottomRoom: CGFloat { wide ? 300 : 250 }
    /// Across-the-screen position of each stop, bottom to top
    private let xs: [CGFloat] = [0.5, 0.72, 0.6, 0.3, 0.28, 0.6, 0.72, 0.45]

    var height: CGFloat { topRoom + bottomRoom + CGFloat(count - 1) * spacing }

    func center(_ level: Int) -> CGPoint {
        let i = level - 1
        return CGPoint(x: bandLeft + band * xs[i % xs.count], y: height - bottomRoom - CGFloat(i) * spacing)
    }

    /// +1 when the middle of the screen is to the right of this stop, -1 when it's to the left
    func towardMiddle(_ level: Int) -> CGFloat { center(level).x < width / 2 ? 1 : -1 }

    var finish: CGPoint { CGPoint(x: width * 0.5, y: center(count).y - spacing * 0.85) }

    var pathPoints: [CGPoint] {
        let start = CGPoint(x: width * 0.5, y: height + 40)
        return [start] + (1...count).map(center) + [finish]
    }
}

/// A smooth curve through every point (Catmull-Rom turned into cubic Béziers)
private struct TrailPath: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard points.count > 1 else { return p }
        p.move(to: points[0])
        for i in 0..<points.count - 1 {
            let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            p.addCurve(to: p2, control1: c1, control2: c2)
        }
        return p
    }
}

// MARK: - Small pieces

private struct StarRow: View {
    let stars: Int
    let size: CGFloat

    var body: some View {
        HStack(spacing: size * 0.1) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(i < stars ? Color.bmYellow : Color(hex: "1F5E2C").opacity(0.45))
                    .shadow(color: .black.opacity(i < stars ? 0.25 : 0), radius: 1, y: 1)
                    .offset(y: i == 1 ? size * 0.2 : 0)
            }
        }
    }
}

/// Soft glow ring that keeps growing out from the stop to play next
private struct PulseRing: View {
    let color: Color
    let size: CGFloat
    @State private var grow = false

    var body: some View {
        Circle()
            .stroke(color, lineWidth: size * 0.08)
            .frame(width: size, height: size)
            .scaleEffect(grow ? 1.45 : 1)
            .opacity(grow ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { grow = true }
            }
    }
}

private struct HoveringBeemoo: View {
    let size: CGFloat
    @State private var bob = false

    var body: some View {
        RemoteImage(filename: "mascot/BEEMOO_02_Flying_Hovering.png")
            .scaledToFit()
            .frame(width: size, height: size)
            .offset(y: bob ? -6 : 6)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { bob = true }
            }
    }
}

/// Bushes and flowers along both edges of the trail
private struct JunglePlants: View {
    let layout: TrailLayout
    private let plants = ["🌴", "🌿", "🌺", "🍃", "🌳", "🌼", "🌿", "🌴", "🌺", "🍄"]

    var body: some View {
        let rows = Int(layout.height / (layout.spacing * 0.55))
        // Wide screens get extra columns of jungle beside the trail
        let columns: [CGFloat] = layout.width > 900 ? [0.05, 0.16, 0.84, 0.95] : [0.07, 0.93]
        ForEach(0..<rows, id: \.self) { r in
            ForEach(columns.indices, id: \.self) { c in
                // Stagger rows and columns so the plants don't line up in a grid
                if (r + c) % 2 == 0 {
                    let y = CGFloat(r) * layout.spacing * 0.55 + 60 + (c % 2 == 0 ? 0 : layout.spacing * 0.2)
                    Text(plants[(r * 3 + c) % plants.count])
                        .font(.system(size: layout.wide ? 54 : 38))
                        .position(x: layout.width * columns[c], y: y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Grassy jungle floor, darker at the top where the trail heads into the trees
struct JungleTrailBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "1F6B33"), Color(hex: "3E9B45"), Color(hex: "7CC95A")],
            startPoint: .top, endPoint: .bottom
        )
        .overlay {
            // Soft light patches so the grass isn't flat
            GeometryReader { geo in
                ForEach(0..<6, id: \.self) { i in
                    Ellipse()
                        .fill(.white.opacity(0.06))
                        .frame(width: geo.size.width * 0.7, height: geo.size.width * 0.35)
                        .position(x: geo.size.width * (i % 2 == 0 ? 0.25 : 0.75),
                                  y: geo.size.height * (0.1 + CGFloat(i) * 0.16))
                }
            }
        }
        .ignoresSafeArea()
    }
}
