import SwiftUI

@Observable
final class APIClient {
    var catalog: Catalog
    var childName: String = "Emma"
    var activitiesCompletedToday: Int = 0

    /// Base URL for the Django backend (media files served at /media/s-sound/).
    let baseURL: URL
    let mediaBaseURL: URL

    init() {
        self.catalog = SeedData.loadCatalog()
        // Default to localhost for development. Change for production.
        self.baseURL = URL(string: "http://localhost:8000")!
        self.mediaBaseURL = URL(string: "http://localhost:8000/media/s-sound/")!
    }

    /// Full URL for a media asset filename (e.g. "BEEMOO_Initial_S_Sun.png").
    func mediaURL(for filename: String) -> URL {
        mediaBaseURL.appendingPathComponent(filename)
    }
}
