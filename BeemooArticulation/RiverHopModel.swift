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
    /// Where the feet are across each elephant image, as a fraction of its width. The art faces right
    /// with the trunk raised, so the feet sit left of the image center. The jump frame's anchor keeps the
    /// body in the same place when the frames swap. Default to the measured values of the current art.
    let standAnchorX: Double?
    let jumpAnchorX: Double?
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

    /// How many stone gaps fit across the free part of the screen while following: the current
    /// stone, plus the next two or three ahead so the child can see where the elephant is going.
    var followSpanGaps: CGFloat = 3.4
    /// Upper limit on the elephant's height as a share of the screen height (keeps phones from over-zooming).
    var maxElephantScreenHeight: CGFloat = 0.36
    /// Where the elephant's feet sit vertically on screen (0 = top, 1 = bottom).
    var feetScreenY: CGFloat = 0.64
    /// Horizontal position on screen of the camera's center: the middle of the area right of the word panel.
    var anchorX: CGFloat = 0.7
    /// Width of the screen area right of the word panel, as a share of the screen width.
    var freeWidthFraction: CGFloat = 0.6

    var screenW: CGFloat = 1
    var screenH: CGFloat = 1

    var drops: [WaterDrop] = []
    var ripples: [Ripple] = []

    /// Called when the feet touch a stone or the far bank. `reachedEnd` is true on the far bank.
    var onLand: ((_ reachedEnd: Bool) -> Void)?

    var standAnchorX: CGFloat { CGFloat(config.standAnchorX ?? 0.351) }
    var jumpAnchorX: CGFloat { CGFloat(config.jumpAnchorX ?? 0.366) }
    /// Typical distance between stones, used to frame the camera
    private var stoneGap: CGFloat {
        let s = config.stones
        guard s.count > 1, let first = s.first, let last = s.last else { return 105 }
        return CGFloat(last.x - first.x) / CGFloat(s.count - 1)
    }

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

    /// Close on the elephant, aimed at where it will LAND (not where it is mid-air), so the camera
    /// glides sideways during a hop and never rides the jump arc. The elephant sits in the left third
    /// of the free area, with the next stones ahead of it in view.
    private func followCamera() -> (x: CGFloat, y: CGFloat, z: CGFloat) {
        let freeW = screenW * freeWidthFraction
        let spanZoom = freeW / (followSpanGaps * stoneGap)
        let capZoom = maxElephantScreenHeight * screenH / elephantHeight
        let p = phase == .flight || phase == .windup ? to : pos
        // Near the left edge of the river the camera can't scroll further left, so the elephant
        // would slide behind the word panel. Zoom in just enough to keep its body right of the panel.
        let freeMinX = (anchorX - freeWidthFraction / 2) * screenW + 12
        let bodyLeft = standAnchorX * elephantHeight * 1.35     // tail end of the elephant, from the feet
        let edgeZoom = freeMinX / max(p.x - bodyLeft, 1)
        let z = max(overviewCamera().z, min(max(spanZoom, edgeZoom), capZoom * 1.15))
        let visibleH = screenH / z
        let lookAhead = 0.17 * freeW / z
        return clamp(x: p.x + lookAhead, y: p.y - (feetScreenY - 0.5) * visibleH, z: z)
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

    /// Pitch of the body during flight, in radians (nose up on take-off, nose down on landing).
    var pitch: CGFloat = 0

    private var flightDuration: CGFloat {
        let dist = hypot(to.x - from.x, to.y - from.y)
        return 0.44 + dist / 1100
    }

    /// Apex height above the higher end of the hop: a real-feeling hop, about half the elephant's height.
    private var arcHeight: CGFloat {
        let dist = hypot(to.x - from.x, to.y - from.y)
        return 30 + dist * 0.18
    }

    func tick(dt rawDt: CGFloat) {
        let dt = min(rawDt, 1.0 / 30.0)

        switch phase {
        case .windup:
            // Anticipation: crouch, lean back a touch
            timer += dt
            pitch += (-0.05 - pitch) * min(1, 14 * dt)
            if timer >= 0.16 {
                phase = .flight
                timer = 0
                sTarget = 1.08
                sv += 5      // push off
            }
        case .flight:
            // Projectile: constant horizontal speed, parabolic height, so the arc reads as a real jump
            timer += dt
            let T = flightDuration
            let u = min(timer / T, 1)
            let h = arcHeight + max(0, from.y - to.y)        // clear the higher end when hopping up
            let x = lerp(from.x, to.x, u)
            let y = lerp(from.y, to.y, u) - 4 * h * u * (1 - u)
            pos = CGPoint(x: x, y: y)
            // Body follows the direction of travel (softened), so it noses up then down
            let vx = (to.x - from.x) / T
            let vy = ((to.y - from.y) - 4 * h * (1 - 2 * u)) / T
            pitch = max(-0.32, min(0.32, atan2(vy, max(vx, 1)) * 0.45))
            // Stretch on the way up, relax at the apex, brace just before touching down
            sTarget = u < 0.5 ? 1.08 - 0.12 * u : (u > 0.85 ? 0.97 : 1.02)
            if u >= 1 { land() }
        case .celebration:
            timer += dt
            if timer.truncatingRemainder(dividingBy: 0.7) < dt { sv -= 5 }
        case .idle:
            sTarget = 1
        }

        // Springs
        sv += (-420 * (s - sTarget) - 32 * sv) * dt
        s = min(max(s + sv * dt, 0.7), 1.25)
        if phase != .flight && phase != .windup { pitch += -pitch * min(1, 12 * dt) }
        lean = pitch
        for k in stoneDip.indices {
            stoneDipV[k] += (-160 * stoneDip[k] - 10 * stoneDipV[k]) * dt
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
        sv = -6.5        // squash on impact, then the spring settles it
        pitch = 0.06     // small forward nod as the weight lands
        punch = 0.01
        let stone = index - 1
        let onStone = stone >= 0 && stone < stoneDip.count
        if onStone { stoneDipV[stone] += 60 }
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
