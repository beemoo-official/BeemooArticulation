import SwiftUI

@Observable
final class APIClient {
    var catalog: Catalog
    var childName: String = "Emma"

    init() {
        self.catalog = SeedData.loadCatalog()
    }
}
