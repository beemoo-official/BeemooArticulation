import SwiftUI
import UIKit

// MARK: - Config (from the screen JSON payload)

/// Elephant River Hop layout. Positions are in "world units" = pixels of the river background.
/// Image sizes assume the tightly cropped art (no empty space around the elephant or stone).
struct RiverHopConfig: Codable, Sendable {
    let backgroundAsset: String
    let standAsset: String
    let jumpAsset: String
    let stoneAsset: String
    let backgroundWidth: Double
    let backgroundHeight: Double
    /// Elephant height in world units (the jump frame is drawn 4% taller). Anchored at its feet.
    let elephantHeight: Double
    /// Stone draw width in world units.
    let stoneWidth: Double
    /// Where the feet land on the stone image, as a fraction from its top (0.30 = front half of the flat top).
    let stoneLandingY: Double
    let start: Point
    let stones: [Point]
    let end: Point

    struct Point: Codable, Sendable {
        let x: Double
        let y: Double
    }
}

// MARK: - River hop physics + camera

@Observable
final class RiverHopState {
    let config: RiverHopConfig

    // Images (preloaded before the scene shows)
    var backgroundImage: UIImage?
    var standImage: UIImage?
    var jumpImage: UIImage?
    var stoneImage: UIImage?
    var isReady = false

    /// Feet positions in hop order: start bank, 9 stones, far bank.
    let path: [CGPoint]
    /// 0 = start bank; 1...stones.count = on a stone; path.count - 1 = far bank.
    var index = 0
    var pos: CGPoint

    enum Phase { case idle, windup, flight, celebration }
    var phase: Phase = .idle
    private var timer: CGFloat = 0
    private var from: CGPoint = .zero
    private var to: CGPoint = .zero

    // Squash/stretch spring (1 = rest), lean in radians
    var s: CGFloat = 1
    private var sv: CGFloat = 0
    private var sTarget: CGFloat = 1
    var lean: CGFloat = 0

    // Each stone dips a little when landed on
    var stoneDip: [CGFloat]
    private var stoneDipV: [CGFloat]

    // Camera: (camX, camY) is the world point drawn at (anchorX × width, height / 2)
    var camX: CGFloat = 0
    var camY: CGFloat = 0
    var zoom: CGFloat = 1
    var punch: CGFloat = 0
    enum CameraMode { case overview, pushIn, follow, pullOut }
    var cameraMode: CameraMode = .overview
    private var camTimer: CGFloat = 0
    private var camFrom = (x: CGFloat(0), y: CGFloat(0), z: CGFloat(1))

    /// Elephant height as a share of the screen height while following.
    var elephantScreenHeight: CGFloat = 0.35
    /// Where the elephant's feet sit vertically on screen (0 = top, 1 = bottom).
    var feetScreenY: CGFloat = 0.72
    /// Horizontal position on screen of the camera's center, so the elephant stays right of the word card.
    var anchorX: CGFloat = 0.62

    var screenW: CGFloat = 1
    var screenH: CGFloat = 1

    var drops: [WaterDrop] = []
    var ripples: [Ripple] = []

    /// Called when the feet touch a stone or the far bank. `reachedEnd` is true on the far bank.
    var onLand: ((_ reachedEnd: Bool) -> Void)?

    var bw: CGFloat { CGFloat(config.backgroundWidth) }
    var bh: CGFloat { CGFloat(config.backgroundHeight) }
    var elephantHeight: CGFloat { CGFloat(config.elephantHeight) }
    var showsJumpFrame: Bool { phase == .flight }
    var hopCount: Int { path.count - 1 }

    init(config: RiverHopConfig) {
        self.config = config
        let pts = [config.start] + config.stones + [config.end]
        path = pts.map { CGPoint(x: $0.x, y: $0.y) }
        pos = path[0]
        stoneDip = Array(repeating: 0, count: config.stones.count)
        stoneDipV = Array(repeating: 0, count: config.stones.count)
    }

    // MARK: Loading

    func preload(apiClient: APIClient) async {
        async let b = Self.loadImage(config.backgroundAsset, from: apiClient)
        async let st = Self.loadImage(config.standAsset, from: apiClient)
        async let j = Self.loadImage(config.jumpAsset, from: apiClient)
        async let sn = Self.loadImage(config.stoneAsset, from: apiClient)
        backgroundImage = await b
        standImage = await st
        jumpImage = await j
        stoneImage = await sn
        isReady = backgroundImage != nil && standImage != nil && stoneImage != nil
    }

    private static func loadImage(_ path: String, from apiClient: APIClient) async -> UIImage? {
        if let cached = ImageCache.shared.image(for: path) { return cached }
        let url = apiClient.mediaURL(for: path)
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let img = UIImage(data: data) else { return nil }
        ImageCache.shared.store(img, for: path)
        return img
    }

    // MARK: Screen + camera

    func updateScreenSize(screenW: CGFloat, screenH: CGFloat) {
        self.screenW = max(screenW, 1)
        self.screenH = max(screenH, 1)
        if cameraMode == .overview { applyCamera(overviewCamera()) }
    }

    private func overviewCamera() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let z = max(screenW / bw, screenH / bh)     // fill the screen with the whole river
        return clamp(x: bw / 2, y: bh / 2, z: z)
    }

    /// Close on the elephant, aimed at where it will LAND (not where it is mid-air),
    /// so the camera glides sideways during a hop and never rides the jump arc.
    private func followCamera() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let z = max(overviewCamera().z, elephantScreenHeight * screenH / elephantHeight)
        let p = phase == .flight ? to : pos
        let visibleH = screenH / z
        return clamp(x: p.x + 30, y: p.y - (feetScreenY - 0.5) * visibleH, z: z)
    }

    /// Never show past the edges of the background.
    private func clamp(x: CGFloat, y: CGFloat, z: CGFloat) -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let leftSpan = anchorX * screenW / z, rightSpan = (1 - anchorX) * screenW / z
        let halfH = screenH / 2 / z
        let cx = min(max(x, leftSpan), max(leftSpan, bw - rightSpan))
        let cy = min(max(y, halfH), max(halfH, bh - halfH))
        return (cx, cy, z)
    }

    private func applyCamera(_ c: (x: CGFloat, y: CGFloat, z: CGFloat)) {
        camX = c.x; camY = c.y; zoom = c.z
    }

    /// The "Start" push-in from the whole river to the elephant.
    func startHopping() {
        camFrom = (camX, camY, zoom)
        cameraMode = .pushIn
        camTimer = 0
    }

    // MARK: Hop

    func triggerHop() {
        guard phase == .idle, cameraMode == .follow, index < path.count - 1 else { return }
        from = path[index]
        to = path[index + 1]
        timer = 0
        phase = .windup
        sTarget = 0.84
    }

    func tick(dt rawDt: CGFloat) {
        let dt = min(rawDt, 1.0 / 30.0)

        switch phase {
        case .windup:
            timer += dt
            if timer >= 0.17 {
                phase = .flight
                timer = 0
                sTarget = 1.1
                sv += 4.5
            }
        case .flight:
            timer += dt
            let dist = hypot(to.x - from.x, to.y - from.y)
            let duration = 0.48 + dist / 900
            let u = min(timer / duration, 1)
            let arc = 40 + dist * 0.25
            pos = CGPoint(
                x: lerp(from.x, to.x, 0.5 - cos(.pi * u) / 2),
                y: lerp(from.y, to.y, u) - arc * 4 * u * (1 - u)
            )
            sTarget = u < 0.45 ? 1.1 - 0.2 * u : 1.0 + 0.08 * (u - 0.45)
            lean = 0.14 * (1 - 1.6 * u)
            if u >= 1 { land() }
        case .celebration:
            timer += dt
            if timer.truncatingRemainder(dividingBy: 0.7) < dt { sv -= 5 }
        case .idle:
            sTarget = 1
        }

        // Springs
        sv += (-420 * (s - sTarget) - 38 * sv) * dt
        s = min(max(s + sv * dt, 0.62), 1.3)
        if phase != .flight { lean += -lean * min(1, 10 * dt) }
        for k in stoneDip.indices {
            stoneDipV[k] += (-140 * stoneDip[k] - 9 * stoneDipV[k]) * dt
            stoneDip[k] += stoneDipV[k] * dt
        }

        // Camera
        switch cameraMode {
        case .overview:
            applyCamera(overviewCamera())
        case .pushIn, .pullOut:
            camTimer += dt
            let duration: CGFloat = cameraMode == .pushIn ? 1.5 : 1.7
            let u = min(camTimer / duration, 1), e = easeInOutCubic(u)
            let target = cameraMode == .pushIn ? followCamera() : overviewCamera()
            camX = lerp(camFrom.x, target.x, e)
            camY = lerp(camFrom.y, target.y, e)
            zoom = exp(lerp(log(camFrom.z), log(target.z), e))
            if u >= 1 {
                if cameraMode == .pushIn {
                    cameraMode = .follow
                    sv -= 4      // little "ready!" bounce
                } else {
                    cameraMode = .overview
                }
            }
        case .follow:
            let target = followCamera(), f = 1 - exp(-3 * dt)
            camX += (target.x - camX) * f
            camY += (target.y - camY) * f
            zoom += (target.z - zoom) * f
        }
        punch *= exp(-7 * dt)

        // Particles
        for k in drops.indices { drops[k].tick(dt: dt) }
        drops.removeAll { $0.age >= $0.lifetime }
        for k in ripples.indices { ripples[k].age += dt }
        ripples.removeAll { $0.age >= $0.lifetime }
    }

    private func land() {
        index += 1
        pos = path[index]
        sTarget = 1
        sv = -7.5
        lean = 0
        punch = 0.012
        let stone = index - 1
        let onStone = stone >= 0 && stone < stoneDip.count
        if onStone { stoneDipV[stone] += 55 }
        splash(at: pos, onStone: onStone)

        let reachedEnd = index >= path.count - 1
        if reachedEnd {
            phase = .celebration
            timer = 0
            camFrom = (camX, camY, zoom)
            cameraMode = .pullOut
            camTimer = 0
            confetti(at: CGPoint(x: pos.x, y: pos.y - elephantHeight))
        } else {
            phase = .idle
        }
        onLand?(reachedEnd)
    }

    // MARK: Particles

    private func splash(at p: CGPoint, onStone: Bool) {
        let colors: [UIColor] = onStone
            ? [UIColor(red: 0.91, green: 0.97, blue: 1, alpha: 1), UIColor(red: 0.5, green: 0.83, blue: 0.95, alpha: 1)]
            : [UIColor(red: 0.85, green: 0.72, blue: 0.47, alpha: 1), UIColor(red: 0.72, green: 0.58, blue: 0.34, alpha: 1)]
        for k in 0..<(onStone ? 18 : 12) {
            let angle = -CGFloat.pi / 2 + CGFloat.random(in: -1.2...1.2)
            let speed = CGFloat.random(in: 90...260)
            drops.append(WaterDrop(x: p.x + CGFloat.random(in: -20...20), y: p.y,
                                   vx: cos(angle) * speed, vy: sin(angle) * speed,
                                   radius: CGFloat.random(in: 2...5.5), lifetime: CGFloat.random(in: 0.5...1.0),
                                   color: colors[k % colors.count], isConfetti: false))
        }
        if onStone {
            ripples.append(Ripple(x: p.x, y: p.y + 14, age: 0, lifetime: 0.9))
            ripples.append(Ripple(x: p.x, y: p.y + 14, age: -0.18, lifetime: 0.9))
        }
    }

    private func confetti(at p: CGPoint) {
        let colors: [UIColor] = [
            UIColor(red: 0.96, green: 0.72, blue: 0.04, alpha: 1), UIColor(red: 1, green: 0.56, blue: 0.69, alpha: 1),
            UIColor(red: 0.49, green: 0.81, blue: 0.29, alpha: 1), UIColor(red: 0.5, green: 0.83, blue: 0.95, alpha: 1),
        ]
        for k in 0..<40 {
            let angle = -CGFloat.pi / 2 + CGFloat.random(in: -1.3...1.3)
            let speed = CGFloat.random(in: 220...480)
            drops.append(WaterDrop(x: p.x, y: p.y, vx: cos(angle) * speed, vy: sin(angle) * speed,
                                   radius: CGFloat.random(in: 4...9), lifetime: CGFloat.random(in: 0.9...1.6),
                                   color: colors[k % colors.count], isConfetti: true))
        }
    }

    // MARK: Helpers

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
    private func easeInOutCubic(_ t: CGFloat) -> CGFloat { t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2 }
}

// MARK: - Particles

struct WaterDrop {
    var x, y, vx, vy: CGFloat
    let radius: CGFloat
    let lifetime: CGFloat
    let color: UIColor
    let isConfetti: Bool
    var age: CGFloat = 0
    var rotation: CGFloat = .random(in: 0...6)

    var alpha: CGFloat { max(0, 1 - age / lifetime) }

    mutating func tick(dt: CGFloat) {
        vy += 900 * dt
        x += vx * dt
        y += vy * dt
        if isConfetti { rotation += 8 * dt }
        age += dt
    }
}

struct Ripple {
    let x, y: CGFloat
    var age: CGFloat
    let lifetime: CGFloat
}
