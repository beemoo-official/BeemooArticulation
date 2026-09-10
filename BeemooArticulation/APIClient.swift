import SwiftUI

@Observable
final class APIClient {
    var catalog: Catalog
    var childName: String = "Emma"
    var activitiesCompletedToday: Int = 0

    init() {
        self.catalog = SeedData.loadCatalog()
    }
}
