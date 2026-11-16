import SwiftUI

// MARK: - SpotMap model

/// Describes tappable spots on an image, with positions as fractions of image size (0–1).
/// Decoded from the screen JSON payload so the same view works for any sound's art.
struct SpotMap: Codable, Sendable {
    let asset: String
    let imageWidth: Int
    let imageHeight: Int
    let spots: [Spot]
    /// Visible part of the art as fractions of the image [minX, minY, maxX, maxY]; the rest is
    /// transparent padding. Lets the layout size the art by what you see. Defaults to the whole image.
    let contentBounds: [Double]?

    struct Spot: Codable, Sendable, Identifiable {
        let id: String
        let x: Double   // center x as fraction of image width
        let y: Double   // center y as fraction of image height
        let r: Double   // radius as fraction of image width
    }

    var aspectRatio: CGFloat {
        guard imageHeight > 0 else { return 1 }
        return CGFloat(imageWidth) / CGFloat(imageHeight)
    }

    /// `contentBounds` as a unit rect (whole image when absent or malformed)
    var contentRect: CGRect {
        guard let b = contentBounds, b.count == 4, b[2] > b[0], b[3] > b[1] else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        return CGRect(x: b[0], y: b[1], width: b[2] - b[0], height: b[3] - b[1])
    }
}

// MARK: - SpotTargetImage view

/// Displays an image with tappable spot overlays positioned by fractional coordinates.
/// Completed spots show a yellow fill with a white star. Pending spots are invisible
/// (or translucent red when `showDebug` is true).
struct SpotTargetImage: View {
    let spotMap: SpotMap
    let completedSpots: Set<String>
    let onTap: (SpotMap.Spot) -> Void
    var showDebug: Bool = false

    var body: some View {
        RemoteImage(filename: spotMap.asset)
            .aspectRatio(spotMap.aspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    ForEach(spotMap.spots) { spot in
                        spotTarget(spot: spot, in: geo.size)
                    }
                }
            }
    }

    private func spotTarget(spot: SpotMap.Spot, in size: CGSize) -> some View {
        let centerX = spot.x * size.width
        let centerY = spot.y * size.height
        // Draw the star at the spot's own size so neighbours don't overlap on small screens,
        // but keep a 44pt touch target
        let diameter = spot.r * size.width * 2 * 1.15
        let hitDiameter = max(diameter, 44)
        let isCompleted = completedSpots.contains(spot.id)

        return ZStack {
            if isCompleted {
                // Completed: yellow circle with white star
                Circle()
                    .fill(Color.bmYellow)
                    .frame(width: diameter, height: diameter)
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.system(size: diameter * 0.4))
                            .foregroundStyle(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
            } else if showDebug {
                // Debug: translucent red to check alignment
                Circle()
                    .fill(Color.red.opacity(0.35))
                    .frame(width: diameter, height: diameter)
            }
        }
        .frame(width: hitDiameter, height: hitDiameter)
        .contentShape(Circle())
        .position(x: centerX, y: centerY)
        .accessibilityLabel("Spot \(spot.id)")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            guard !isCompleted else { return }
            onTap(spot)
        }
    }
}
