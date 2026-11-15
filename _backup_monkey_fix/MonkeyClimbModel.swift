import SwiftUI
import UIKit

// MARK: - Config (from JSON payload)

struct MonkeyClimbConfig: Codable, Sendable {
    let treeAsset: String
    let crouchAsset: String
    let jumpAsset: String
    let treeWidth: Int
    let treeHeight: Int
    let steps: [Step]

    struct Step: Codable, Sendable, Identifiable {
        let id: String
        let x: Double    // plank center, fraction of tree width
        let topY: Double  // top surface, fraction of tree height
    }

    var tw: CGFloat { CGFloat(treeWidth) }
    var th: CGFloat { CGFloat(treeHeight) }
}

// MARK: - Monkey physics model

@Observable
final class MonkeyClimbState {
    let config: MonkeyClimbConfig

    // Images (preloaded)
    var treeImage: UIImage?
    var crouchImage: UIImage?
    var jumpImage: UIImage?
    var isReady = false

    // Current step (0-based, starts at 0 = bottom plank)
    var currentStep: Int = 0
    var monkeyX: CGFloat = 0
    var monkeyFeetY: CGFloat = 0

    // Jump state
    enum Phase { case idle, windup, flight, landing, celebration }
    var phase: Phase = .idle
    var jumpTimer: CGFloat = 0
    var jumpFromX: CGFloat = 0
    var jumpFromY: CGFloat = 0
    var jumpToX: CGFloat = 0
    var jumpToY: CGFloat = 0

    // Squash spring
    var s: CGFloat = 1.0          // current squash
    var sv: CGFloat = 0           // squash velocity
    var sTarget: CGFloat = 1.0

    // Lean
    var lean: CGFloat = 0         // radians
    var jumpDir: CGFloat = 1      // 1 or -1

    // Camera
    var camX: CGFloat = 0
    var camY: CGFloat = 0
    var zoom: CGFloat = 1
    var punch: CGFloat = 0

    // Intro/outro
    enum CameraMode { case overview, pushIn, follow, pullOut }
    var cameraMode: CameraMode = .overview
    var cameraTransitionTimer: CGFloat = 0
    var overviewZoom: CGFloat = 1
    var closeZoom: CGFloat = 1.5

    // Particles
    var leaves: [LeafParticle] = []

    // Completion
    var isComplete = false

    // Screen size
    var screenW: CGFloat = 0
    var screenH: CGFloat = 0

    var tw: CGFloat { config.tw }
    var th: CGFloat { config.th }
    var monkeyHeight: CGFloat { 0.106 * th }

    init(config: MonkeyClimbConfig) {
        self.config = config
    }

    func preload(apiClient: APIClient) async {
        async let t = loadImage(config.treeAsset, from: apiClient)
        async let c = loadImage(config.crouchAsset, from: apiClient)
        async let j = loadImage(config.jumpAsset, from: apiClient)
        treeImage = await t
        crouchImage = await c
        jumpImage = await j

        // Place monkey on step 0
        if let step = config.steps.first {
            monkeyX = CGFloat(step.x) * tw
            monkeyFeetY = (CGFloat(step.topY) + 0.007) * th
        }
        isReady = true
    }

    private func loadImage(_ path: String, from apiClient: APIClient) async -> UIImage? {
        if let cached = ImageCache.shared.image(for: path) { return cached }
        let url = apiClient.mediaURL(for: path)
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let img = UIImage(data: data) else { return nil }
        ImageCache.shared.store(img, for: path)
        return img
    }

    // MARK: - Setup camera

    func setupCamera(screenW: CGFloat, screenH: CGFloat) {
        self.screenW = screenW
        self.screenH = screenH
        overviewZoom = 0.94 * screenH / th
        closeZoom = min(1.5, 0.3 * screenH / monkeyHeight)
        camX = tw / 2
        camY = th / 2
        zoom = overviewZoom
    }

    // MARK: - Step position in world coords

    func stepPosition(_ index: Int) -> CGPoint {
        guard index < config.steps.count else { return .zero }
        let step = config.steps[index]
        return CGPoint(
            x: CGFloat(step.x) * tw,
            y: (CGFloat(step.topY) + 0.007) * th
        )
    }

    // MARK: - Start climbing (intro push-in)

    func startClimbing() {
        cameraMode = .pushIn
        cameraTransitionTimer = 0
    }

    // MARK: - Trigger jump

    func triggerJump() {
        guard phase == .idle, currentStep + 1 < config.steps.count else { return }

        let from = stepPosition(currentStep)
        let to = stepPosition(currentStep + 1)

        jumpFromX = from.x
        jumpFromY = from.y
        jumpToX = to.x
        jumpToY = to.y
        jumpDir = to.x >= from.x ? 1 : -1
        jumpTimer = 0
        phase = .windup
        sTarget = 0.84
    }

    // MARK: - Physics tick

    func tick(dt rawDt: CGFloat) {
        let dt = min(rawDt, 1.0 / 30.0)

        // Squash spring
        sv += (-420 * (s - sTarget) - 38 * sv) * dt
        s += sv * dt
        s = max(0.62, min(1.3, s))

        // Camera punch decay
        punch *= exp(-7 * dt)

        // Leaf particles
        for i in leaves.indices {
            leaves[i].tick(dt: dt, gravity: 1.13 * th)
        }
        leaves.removeAll { $0.alpha <= 0 }

        // Camera modes
        switch cameraMode {
        case .overview:
            camX = tw / 2
            camY = th / 2
            zoom = overviewZoom

        case .pushIn:
            cameraTransitionTimer += dt
            let t = min(cameraTransitionTimer / 1.5, 1.0)
            let e = easeInOutCubic(t)
            let targetX = followTargetX
            let targetY = followTargetY
            camX = lerp(tw / 2, targetX, e)
            camY = lerp(th / 2, targetY, e)
            zoom = exp(lerp(log(overviewZoom), log(closeZoom), e))
            if t >= 1.0 {
                cameraMode = .follow
                sv = -4  // ready bounce
            }

        case .follow:
            let targetX = followTargetX
            let targetY = followTargetY
            let f = 1 - exp(-4.2 * dt)
            camX += (targetX - camX) * f
            camY += (targetY - camY) * f
            zoom = closeZoom

        case .pullOut:
            cameraTransitionTimer += dt
            let t = min(cameraTransitionTimer / 1.7, 1.0)
            let e = easeInOutCubic(t)
            let startX = followTargetX
            let startY = followTargetY
            camX = lerp(startX, tw / 2, e)
            camY = lerp(startY, th / 2, e)
            zoom = exp(lerp(log(closeZoom), log(overviewZoom), e))
            if t >= 1.0 && !isComplete {
                isComplete = true
            }
        }

        // Jump phases
        switch phase {
        case .idle:
            lean += (0 - lean) * min(1, 10 * dt)

        case .windup:
            jumpTimer += dt
            if jumpTimer >= 0.17 {
                phase = .flight
                jumpTimer = 0
                sTarget = 1.1
                sv += 4.5
            }

        case .flight:
            jumpTimer += dt
            let u = min(jumpTimer / 0.52, 1.0)
            let cosU = cos(.pi * u)
            monkeyX = lerp(jumpFromX, jumpToX, 0.5 - cosU / 2)
            monkeyFeetY = lerp(jumpFromY, jumpToY, u) - 0.075 * th * 4 * u * (1 - u)

            if u < 0.45 {
                sTarget = 1.1 - 0.2 * u
            } else {
                sTarget = 1.0 + 0.08 * (u - 0.45)
            }
            lean = jumpDir * 0.16 * (1 - 1.6 * u)

            if u >= 1.0 {
                // Landing
                phase = .landing
                jumpTimer = 0
                currentStep += 1
                let pos = stepPosition(currentStep)
                monkeyX = pos.x
                monkeyFeetY = pos.y
                sTarget = 1.0
                sv = -7.5
                punch = 0.035
                spawnLandingLeaves()

                // Check if reached top
                if currentStep >= config.steps.count - 1 {
                    phase = .celebration
                    cameraMode = .pullOut
                    cameraTransitionTimer = 0
                    spawnCelebrationLeaves()
                }
            }

        case .landing:
            jumpTimer += dt
            lean += (0 - lean) * min(1, 10 * dt)
            if jumpTimer >= 0.2 {
                phase = .idle
            }

        case .celebration:
            jumpTimer += dt
            lean += (0 - lean) * min(1, 10 * dt)
            // Little bounce every 0.7s
            if jumpTimer.truncatingRemainder(dividingBy: 0.7) < dt {
                sv -= 5
            }
        }
    }

    // MARK: - Camera helpers

    private var followTargetX: CGFloat {
        lerp(tw / 2, monkeyX, 0.55)
    }

    private var followTargetY: CGFloat {
        (monkeyFeetY - 0.5 * monkeyHeight) - 0.07 * screenH / max(zoom, 0.01)
    }

    private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    // MARK: - Particles

    func spawnLandingLeaves() {
        let greens: [UIColor] = [
            UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1),
            UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1),
            UIColor(red: 0.15, green: 0.6, blue: 0.15, alpha: 1),
            UIColor(red: 0.7, green: 0.65, blue: 0.4, alpha: 1), // tan
        ]
        for _ in 0..<14 {
            let angle = CGFloat.random(in: -.pi/2 - 1.1 ... -.pi/2 + 1.1)
            let speed = CGFloat.random(in: 0.32...0.98) * th
            leaves.append(LeafParticle(
                x: monkeyX + CGFloat.random(in: -10...10),
                y: monkeyFeetY,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -8...8),
                lifetime: CGFloat.random(in: 0.7...1.3),
                color: greens.randomElement()!,
                size: CGFloat.random(in: 6...12)
            ))
        }
    }

    func spawnCelebrationLeaves() {
        let colors: [UIColor] = [
            UIColor(red: 1, green: 0.85, blue: 0, alpha: 1),
            UIColor(red: 1, green: 0.65, blue: 0, alpha: 1),
            UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1),
            UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1),
        ]
        for _ in 0..<44 {
            let angle = CGFloat.random(in: -.pi ... 0)
            let speed = CGFloat.random(in: 0.5...1.4) * th
            leaves.append(LeafParticle(
                x: monkeyX + CGFloat.random(in: -30...30),
                y: monkeyFeetY - monkeyHeight,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -10...10),
                lifetime: CGFloat.random(in: 0.8...1.5),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16)
            ))
        }
    }
}

// MARK: - Leaf particle

struct LeafParticle {
    var x, y, vx, vy: CGFloat
    var rotation, rotSpeed: CGFloat
    var lifetime, age: CGFloat
    let color: UIColor
    let size: CGFloat

    init(x: CGFloat, y: CGFloat, vx: CGFloat, vy: CGFloat,
         rotation: CGFloat, rotSpeed: CGFloat, lifetime: CGFloat,
         color: UIColor, size: CGFloat) {
        self.x = x; self.y = y; self.vx = vx; self.vy = vy
        self.rotation = rotation; self.rotSpeed = rotSpeed
        self.lifetime = lifetime; self.age = 0
        self.color = color; self.size = size
    }

    var alpha: CGFloat { max(0, 1 - age / lifetime) }

    mutating func tick(dt: CGFloat, gravity: CGFloat) {
        vy += gravity * dt
        x += vx * dt
        y += vy * dt
        rotation += rotSpeed * dt
        age += dt
    }
}
