import UIKit

/// Calls `onFrame` once per screen refresh (60 or 120 Hz) with the time since the last frame.
/// Drives MonkeyClimbState.tick so the physics run every frame instead of through SwiftUI animations.
final class FrameDriver: NSObject {
    var onFrame: ((CGFloat) -> Void)?
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0

    func start() {
        stop()
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        link.add(to: .main, forMode: .common)
        self.link = link
        lastTimestamp = 0
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        let dt = lastTimestamp == 0 ? 1.0 / 60.0 : link.timestamp - lastTimestamp
        lastTimestamp = link.timestamp
        onFrame?(CGFloat(dt))
    }
}
