import SwiftUI
import UIKit

/// A UIHostingController that forces landscape orientation.
/// Used to present the activity runner — SwiftUI's fullScreenCover
/// does not reliably respect orientation preferences.
class LandscapeHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}

/// Presents a SwiftUI view in a forced-landscape full-screen modal via UIKit.
enum LandscapePresenter {
    static func present<V: View>(_ view: V) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let root = windowScene.windows.first?.rootViewController else { return }

        // Walk to the topmost presented VC
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        let host = LandscapeHostingController(rootView: view)
        host.modalPresentationStyle = .fullScreen
        host.modalTransitionStyle = .crossDissolve

        // Set the mask so the AppDelegate agrees
        AppDelegate.orientationLock.mask = .landscape

        top.present(host, animated: true)
    }

    static func dismiss() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let root = windowScene.windows.first?.rootViewController else { return }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        AppDelegate.orientationLock.mask = .portrait
        top.dismiss(animated: true) {
            // Force re-query after dismiss
            root.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
}
