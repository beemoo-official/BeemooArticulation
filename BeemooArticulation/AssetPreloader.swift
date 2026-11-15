import SwiftUI

/// Preloads all images for a screen before it renders.
/// Shows a progress bar and logs failures.
@Observable
final class AssetPreloader {
    var totalAssets = 0
    var loadedAssets = 0
    var failedAssets: [String] = []
    var isComplete = false
    var progress: Double {
        guard totalAssets > 0 else { return 0 }
        return Double(loadedAssets) / Double(totalAssets)
    }

    /// Preload a list of asset paths. Returns true if all loaded.
    @discardableResult
    func preload(_ paths: [String], from apiClient: APIClient) async -> Bool {
        let unique = Array(Set(paths))
        totalAssets = unique.count
        loadedAssets = 0
        failedAssets = []
        isComplete = false

        await withTaskGroup(of: (String, Bool).self) { group in
            for path in unique {
                group.addTask {
                    // Already cached?
                    if ImageCache.shared.image(for: path) != nil {
                        return (path, true)
                    }

                    let url = apiClient.mediaURL(for: path)

                    // Retry up to 3 times with backoff
                    for attempt in 0..<3 {
                        if attempt > 0 {
                            try? await Task.sleep(for: .milliseconds(500 * attempt))
                        }
                        do {
                            let (data, response) = try await URLSession.shared.data(from: url)
                            guard let http = response as? HTTPURLResponse,
                                  http.statusCode == 200,
                                  let image = UIImage(data: data) else {
                                continue
                            }
                            ImageCache.shared.store(image, for: path)
                            return (path, true)
                        } catch {
                            continue
                        }
                    }

                    // All retries failed
                    print("⚠️ ASSET LOAD FAILED: \(path) from \(url)")
                    return (path, false)
                }
            }

            for await (path, success) in group {
                loadedAssets += 1
                if !success {
                    failedAssets.append(path)
                }
            }
        }

        isComplete = true

        if !failedAssets.isEmpty {
            print("❌ ASSET PRELOAD: \(failedAssets.count) of \(totalAssets) FAILED:")
            for f in failedAssets {
                print("   - \(f)")
            }
        } else {
            print("✅ ASSET PRELOAD: all \(totalAssets) assets loaded")
        }

        return failedAssets.isEmpty
    }

    /// Extract all image paths referenced in a ScreenConfig
    static func assetPaths(for screen: ScreenConfig) -> [String] {
        var paths: [String] = []

        if let scene = screen.scene { paths.append(scene) }
        if let choices = screen.choices {
            paths.append(contentsOf: choices.map(\.asset))
        }
        if let stimuli = screen.stimuli {
            paths.append(contentsOf: stimuli.map(\.wordImage))
            paths.append(contentsOf: stimuli.compactMap(\.sentenceImage))
        }
        if let spotMap = screen.spotMap {
            paths.append(spotMap.asset)
        }
        if let drag = screen.dragToGoal {
            paths.append(drag.goalBack)
            paths.append(drag.goalFront)
            paths.append(contentsOf: drag.items.map(\.asset))
        }
        if let monkey = screen.monkeyClimb {
            paths.append(monkey.treeAsset)
            paths.append(monkey.crouchAsset)
            paths.append(monkey.jumpAsset)
        }
        if let river = screen.riverHop {
            paths.append(river.backgroundAsset)
            paths.append(river.standAsset)
            paths.append(river.jumpAsset)
            paths.append(river.stoneAsset)
        }

        return paths
    }

    /// Extract all image paths for an entire activity config
    static func allAssetPaths(for config: ActivityConfig) -> [String] {
        var paths: [String] = []
        for screen in config.screens {
            paths.append(contentsOf: assetPaths(for: screen))
        }
        // Add common assets used by all S-sound screens
        paths.append("backgrounds/Jungle_Background.png")
        paths.append("mascot/BEEMOO_02_Flying_Hovering.png")
        paths.append("mascot/BEEMOO_04_Smiling_Happy.png")
        paths.append("ui/speaker_button.png")
        return Array(Set(paths))
    }
}

/// A loading overlay view with progress bar
struct AssetLoadingOverlay: View {
    let preloader: AssetPreloader
    let activityTitle: String

    var body: some View {
        ZStack {
            Color.bmCream.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("beemoo_fly")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text(activityTitle)
                    .font(.baloo2(22))
                    .foregroundStyle(Color.bmNavy)

                VStack(spacing: 8) {
                    ProgressView(value: preloader.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 220)
                        .tint(Color.bmConceptGreen)

                    Text("Loading... \(preloader.loadedAssets)/\(preloader.totalAssets)")
                        .font(.nunito(13))
                        .foregroundStyle(Color.bmNavy62)
                }

                if !preloader.failedAssets.isEmpty {
                    Text("\(preloader.failedAssets.count) images failed to load")
                        .font(.nunito(12))
                        .foregroundStyle(Color.bmOrange)
                }
            }
        }
    }
}
