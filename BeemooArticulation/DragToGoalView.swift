import SwiftUI

// MARK: - Data models (decoded from screen JSON payload)

/// Describes a drag-to-goal game: items dragged into a layered goal area.
struct DragToGoalConfig: Codable, Sendable {
    let goalBack: String
    let goalFront: String
    let goalImageWidth: Int
    let goalImageHeight: Int
    let dropZone: DropZone
    let spots: [GoalSpot]
    let items: [DragItem]

    var goalAspectRatio: CGFloat {
        guard goalImageHeight > 0 else { return 1 }
        return CGFloat(goalImageWidth) / CGFloat(goalImageHeight)
    }

    struct DropZone: Codable, Sendable {
        let centerX: Double
        let centerY: Double
        let radiusX: Double
        let radiusY: Double
    }

    struct GoalSpot: Codable, Sendable, Identifiable {
        let id: String
        let x: Double          // bottom-center x, fraction of goal image
        let y: Double          // bottom-center y, fraction of goal image
        let height: Double     // snake height as fraction of goal image height
    }

    struct DragItem: Codable, Sendable, Identifiable {
        let id: String
        let asset: String
        let startX: Double
        let startY: Double
    }
}

// MARK: - Preloader

/// Loads all images for the drag-to-goal scene before rendering.
@Observable
final class DragToGoalPreloader {
    var pitBack: UIImage?
    var pitFront: UIImage?
    var snakeImages: [String: UIImage] = [:]
    var isReady: Bool = false

    func preload(config: DragToGoalConfig, apiClient: APIClient) async {
        async let back = fetchImage(config.goalBack, from: apiClient)
        async let front = fetchImage(config.goalFront, from: apiClient)

        var snakes: [String: UIImage] = [:]
        for item in config.items {
            if let img = await fetchImage(item.asset, from: apiClient) {
                snakes[item.id] = img
            }
        }

        pitBack = await back
        pitFront = await front
        snakeImages = snakes
        isReady = true
    }

    private func fetchImage(_ filename: String, from apiClient: APIClient) async -> UIImage? {
        if let cached = ImageCache.shared.image(for: filename) {
            return cached
        }
        let url = apiClient.mediaURL(for: filename)
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let image = UIImage(data: data) else { return nil }
        ImageCache.shared.store(image, for: filename)
        return image
    }
}

// MARK: - DragToGoalView

struct DragToGoalView: View {
    let config: DragToGoalConfig
    let screenSize: CGSize
    let onItemDropped: (DragToGoalConfig.DragItem) -> Void
    var showDebug: Bool = false

    @Environment(APIClient.self) private var apiClient
    @State private var preloader = DragToGoalPreloader()

    // Per-snake state — keyed by item ID, stable for the whole round
    @State private var droppedOrder: [String] = []          // IDs in drop order
    @State private var snakeOffsets: [String: CGSize] = [:]  // drag offset
    @State private var snakeDragging: [String: Bool] = [:]
    @State private var snakeInPit: [String: Bool] = [:]      // settled into final spot
    @State private var snakeSettling: [String: Bool] = [:]   // animating above → spot
    @State private var feedbackMessage: String?

    // pitRect: the actual on-screen rect of the aspect-fit pit image
    private var pitRect: CGRect {
        let maxW = screenSize.width * 0.85
        let maxH = screenSize.height * 0.75
        let ar = config.goalAspectRatio
        let fitW = min(maxW, maxH * ar)
        let fitH = fitW / ar
        let x = (screenSize.width - fitW) / 2
        let y = (screenSize.height - fitH) / 2 + screenSize.height * 0.05
        return CGRect(x: x, y: y, width: fitW, height: fitH)
    }

    var body: some View {
        Group {
            if preloader.isReady {
                sceneContent
                    .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .animation(.easeOut(duration: 0.3), value: preloader.isReady)
        .task { await preloader.preload(config: config, apiClient: apiClient) }
    }

    // MARK: - Scene (single ZStack, all children, zIndex controls layering)

    private var sceneContent: some View {
        ZStack {
            // zIndex 0: pit back
            pitImage(preloader.pitBack)
                .zIndex(0)

            // zIndex 1-2: all snakes (one view per snake, stable .id)
            ForEach(config.items) { item in
                snakeView(item)
            }

            // zIndex 5: pit front (always present, never conditional)
            pitImage(preloader.pitFront)
                .zIndex(5)

            // Debug
            if showDebug { debugOverlays.zIndex(10) }

            // Feedback
            if let msg = feedbackMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.nunito(16, weight: .bold))
                        .foregroundStyle(Color.bmNavy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.9)))
                        .padding(.bottom, 20)
                }
                .zIndex(11)
            }
        }
    }

    // MARK: - Pit image (from preloaded UIImage)

    private func pitImage(_ uiImage: UIImage?) -> some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(config.goalAspectRatio, contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .frame(width: pitRect.width, height: pitRect.height)
        .position(x: pitRect.midX, y: pitRect.midY)
        .allowsHitTesting(false)
    }

    // The next snake to drag (first undropped item)
    private var nextSnakeId: String? {
        config.items.first { !droppedOrder.contains($0.id) }?.id
    }

    // MARK: - Single snake view (stable identity, layer changes via zIndex only)

    private func snakeView(_ item: DragToGoalConfig.DragItem) -> some View {
        let isDropped = droppedOrder.contains(item.id)
        let inPit = snakeInPit[item.id] ?? false
        let settling = snakeSettling[item.id] ?? false
        let dragging = snakeDragging[item.id] ?? false
        let offset = snakeOffsets[item.id] ?? .zero
        let isNext = item.id == nextSnakeId

        // Determine position and size
        let posAndSize: (pos: CGPoint, w: CGFloat, h: CGFloat)
        if isDropped, let spotIndex = droppedOrder.firstIndex(of: item.id),
           spotIndex < config.spots.count {
            let spot = config.spots[spotIndex]
            let snakeH = CGFloat(spot.height) * pitRect.height
            let snakeW = snakeAspectWidth(item: item, forHeight: snakeH)
            let bottomY = pitRect.minY + CGFloat(spot.y) * pitRect.height
            let centerX = pitRect.minX + CGFloat(spot.x) * pitRect.width
            let centerY: CGFloat
            if settling && !inPit {
                centerY = bottomY - snakeH / 2 - pitRect.height * 0.15
            } else {
                centerY = bottomY - snakeH / 2
            }
            posAndSize = (CGPoint(x: centerX, y: centerY), snakeW, snakeH)
        } else {
            // Start position — all undropped snakes share a single entry point (bottom center)
            let startPos = CGPoint(
                x: screenSize.width * 0.5,
                y: screenSize.height * 0.82
            )
            let h = screenSize.height * 0.32
            let w = snakeAspectWidth(item: item, forHeight: h)
            posAndSize = (startPos, w, h)
        }

        // Visibility: only the next snake and dropped snakes are visible
        let visible = isDropped || isNext

        // zIndex
        let z: Double
        if dragging {
            z = 8
        } else if isDropped {
            if let idx = droppedOrder.firstIndex(of: item.id), idx < config.spots.count {
                let halfCount = config.spots.count / 2
                z = idx < halfCount ? 3 : 2
            } else {
                z = 2
            }
        } else {
            z = 6
        }

        return Group {
            if let uiImage = preloader.snakeImages[item.id] {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: posAndSize.w, height: posAndSize.h)
        .scaleEffect(dragging ? 1.1 : 1.0)
        .offset(isDropped ? .zero : offset)
        .position(posAndSize.pos)
        .opacity(visible ? 1 : 0)
        .zIndex(z)
        .id(item.id)
        .animation(.easeOut(duration: 0.3), value: visible)
        .gesture(
            (isDropped || !isNext) ? nil :
            DragGesture()
                .onChanged { value in
                    snakeDragging[item.id] = true
                    snakeOffsets[item.id] = value.translation
                }
                .onEnded { value in
                    snakeDragging[item.id] = false
                    let startPos = CGPoint(
                        x: screenSize.width * 0.5,
                        y: screenSize.height * 0.82
                    )
                    let fingerX = startPos.x + value.translation.width
                    let fingerY = startPos.y + value.translation.height

                    if isInsideDropZone(x: fingerX, y: fingerY) {
                        handleValidDrop(item)
                    } else {
                        withAnimation(.spring(duration: 0.4)) {
                            snakeOffsets[item.id] = .zero
                        }
                        feedbackMessage = "Almost! Try again."
                        Task {
                            try? await Task.sleep(for: .milliseconds(1200))
                            feedbackMessage = nil
                        }
                    }
                }
        )
        .animation(.spring(duration: 0.35, bounce: 0.25), value: isDropped)
        .animation(.spring(duration: 0.35, bounce: 0.25), value: inPit)
        .animation(.spring(duration: 0.2), value: dragging)
    }

    // MARK: - Snake aspect ratio helper

    private func snakeAspectWidth(item: DragToGoalConfig.DragItem, forHeight h: CGFloat) -> CGFloat {
        guard let img = preloader.snakeImages[item.id] else { return h }
        let ar = img.size.width / img.size.height
        return h * ar
    }

    // MARK: - Drop handling

    private func handleValidDrop(_ item: DragToGoalConfig.DragItem) {
        // Step 1: add to drop order, mark settling, clear drag offset
        snakeOffsets[item.id] = .zero
        droppedOrder.append(item.id)
        snakeSettling[item.id] = true

        // Step 2: after a beat, spring down into the spot
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
                snakeInPit[item.id] = true
                snakeSettling[item.id] = false
            }
        }

        onItemDropped(item)
    }

    // MARK: - Drop zone hit test

    private func isInsideDropZone(x: CGFloat, y: CGFloat) -> Bool {
        let dz = config.dropZone
        let cx = pitRect.minX + CGFloat(dz.centerX) * pitRect.width
        let cy = pitRect.minY + CGFloat(dz.centerY) * pitRect.height
        let rx = CGFloat(dz.radiusX) * pitRect.width * 1.1
        let ry = CGFloat(dz.radiusY) * pitRect.height * 1.1
        guard rx > 0, ry > 0 else { return false }
        let dx = (x - cx) / rx
        let dy = (y - cy) / ry
        return (dx * dx + dy * dy) <= 1.0
    }

    // MARK: - Debug

    private var debugOverlays: some View {
        ZStack {
            // pitRect outline
            Rectangle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: pitRect.width, height: pitRect.height)
                .position(x: pitRect.midX, y: pitRect.midY)

            // Drop zone ellipse
            let dz = config.dropZone
            Ellipse()
                .fill(Color.blue.opacity(0.15))
                .stroke(Color.blue, lineWidth: 2)
                .frame(
                    width: CGFloat(dz.radiusX) * pitRect.width * 2,
                    height: CGFloat(dz.radiusY) * pitRect.height * 2
                )
                .position(
                    x: pitRect.minX + CGFloat(dz.centerX) * pitRect.width,
                    y: pitRect.minY + CGFloat(dz.centerY) * pitRect.height
                )

            // Spot bottom-center points + snake frames
            ForEach(config.spots) { spot in
                let bottomY = pitRect.minY + CGFloat(spot.y) * pitRect.height
                let centerX = pitRect.minX + CGFloat(spot.x) * pitRect.width
                let snakeH = CGFloat(spot.height) * pitRect.height
                let centerY = bottomY - snakeH / 2

                // Bottom-center marker
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .position(x: centerX, y: bottomY)

                // Snake frame
                Rectangle()
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    .frame(width: snakeH * 0.8, height: snakeH)  // approximate
                    .position(x: centerX, y: centerY)
            }
        }
    }
}
