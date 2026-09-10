import SwiftUI
import UIKit

// MARK: - Shared orientation state

@Observable
final class OrientationLock {
    var mask: UIInterfaceOrientationMask = .portrait
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
    static let orientationLock = OrientationLock()

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        Self.orientationLock.mask
    }
}

// MARK: - Orientation helpers

enum OrientationHelper {
    static func lockLandscape() {
        let lock = AppDelegate.orientationLock
        guard lock.mask != .landscape else { return }
        lock.mask = .landscape

        // Skip force-rotation on iPad
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }

        requestGeometryUpdate(.landscapeRight)
    }

    static func lockPortrait() {
        let lock = AppDelegate.orientationLock
        guard lock.mask != .portrait else { return }
        lock.mask = .portrait

        guard UIDevice.current.userInterfaceIdiom != .pad else { return }

        requestGeometryUpdate(.portrait)
    }

    private static func requestGeometryUpdate(_ orientation: UIInterfaceOrientation) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
            interfaceOrientations: orientation == .portrait ? .portrait : .landscapeRight
        )
        scene.requestGeometryUpdate(geometryPreferences) { error in
            // Rotation request may fail if the device is locked — that's fine
        }

        // Force UIKit to re-query supported orientations
        for window in scene.windows {
            window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}

// MARK: - Orientation-locking VC wrapper

struct OrientationLockView: UIViewControllerRepresentable {
    let orientations: UIInterfaceOrientationMask

    func makeUIViewController(context: Context) -> OrientationLockVC {
        OrientationLockVC(orientations: orientations)
    }

    func updateUIViewController(_ vc: OrientationLockVC, context: Context) {
        vc.orientations = orientations
    }
}

class OrientationLockVC: UIViewController {
    var orientations: UIInterfaceOrientationMask

    init(orientations: UIInterfaceOrientationMask) {
        self.orientations = orientations
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        orientations
    }
}
