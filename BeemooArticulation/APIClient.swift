import SwiftUI

@Observable
final class APIClient {
    var catalog: Catalog
    var childName: String = "Emma"
    var activitiesCompletedToday: Int = 0

    /// Base URL for the Django backend.
    let baseURL: URL
    let mediaBaseURL: URL

    init() {
        self.catalog = SeedData.loadCatalog()
        // Use Mac's local IP for real device testing, localhost for simulator
        #if targetEnvironment(simulator)
        self.baseURL = URL(string: "http://localhost:8000")!
        self.mediaBaseURL = URL(string: "http://localhost:8000/media/")!
        #else
        self.baseURL = URL(string: "http://192.168.5.16:8000")!
        self.mediaBaseURL = URL(string: "http://192.168.5.16:8000/media/")!
        #endif
    }

    /// Full URL for a media asset path (e.g. "sfx/popEffect.mp3" or "mascot/BEEMOO_04_Smiling_Happy.png").
    func mediaURL(for path: String) -> URL {
        mediaBaseURL.appendingPathComponent(path)
    }
}
