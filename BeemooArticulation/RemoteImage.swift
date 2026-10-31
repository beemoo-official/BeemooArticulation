import SwiftUI

/// Loads an image from the Django backend by filename, with disk caching.
/// Falls back to a placeholder while loading, and an SF Symbol on failure.
struct RemoteImage: View {
    let filename: String

    @Environment(APIClient.self) private var apiClient
    @State private var phase: Phase = .loading

    var body: some View {
        Group {
            switch phase {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let image):
                image
                    .resizable()
            case .failed:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(Color.bmNavy50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: filename) {
            await load()
        }
    }

    private func load() async {
        phase = .loading

        let url = apiClient.mediaURL(for: filename)

        // Check disk cache first
        if let cached = ImageCache.shared.image(for: filename) {
            phase = .loaded(Image(uiImage: cached))
            return
        }

        // Download
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let uiImage = UIImage(data: data) else {
                phase = .failed
                return
            }
            ImageCache.shared.store(uiImage, for: filename)
            phase = .loaded(Image(uiImage: uiImage))
        } catch {
            phase = .failed
        }
    }

    private enum Phase {
        case loading
        case loaded(Image)
        case failed
    }
}

// MARK: - Disk cache

/// Simple file-based image cache in Library/Caches/beemoo-images/.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cacheDir: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("beemoo-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func image(for filename: String) -> UIImage? {
        let fileURL = cacheDir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func store(_ image: UIImage, for filename: String) {
        let fileURL = cacheDir.appendingPathComponent(filename)
        if let data = image.pngData() {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
