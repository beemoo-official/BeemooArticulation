import SwiftUI
import UIKit

/// Reusable container for activity scene images.
///
/// The scene is `scaledToFit`, centred, and letterboxed on cream in the area it's given.
/// The `overlays` closure receives the **rendered image rect** so ring/cue positions
/// (expressed as percentages of the image) map correctly on every device.
struct SceneContainer<Overlays: View>: View {
    let sceneName: String
    @ViewBuilder let overlays: (_ imageRect: CGRect) -> Overlays

    var body: some View {
        GeometryReader { geo in
            let imageRect = Self.fittedImageRect(for: sceneName, in: geo.size)

            ZStack {
                Color.bmCream

                Image(sceneName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)

                overlays(imageRect)
            }
        }
    }

    /// Computes the rect of a scaledToFit image within a container.
    static func fittedImageRect(for sceneName: String, in containerSize: CGSize) -> CGRect {
        guard let uiImage = UIImage(named: sceneName) else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let imageSize = uiImage.size
        let scaleX = containerSize.width / imageSize.width
        let scaleY = containerSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        let fittedWidth = imageSize.width * scale
        let fittedHeight = imageSize.height * scale
        let x = (containerSize.width - fittedWidth) / 2
        let y = (containerSize.height - fittedHeight) / 2
        return CGRect(x: x, y: y, width: fittedWidth, height: fittedHeight)
    }
}
