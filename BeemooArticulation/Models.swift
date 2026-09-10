import SwiftUI

// MARK: - Catalog

struct Catalog: Codable, Sendable {
    let version: Int
    let umbrellas: [Umbrella]
    let activities: [Activity]

    func activities(for umbrellaKey: String) -> [Activity] {
        activities.filter { $0.umbrella == umbrellaKey }
    }
}

// MARK: - Umbrella

struct Umbrella: Codable, Sendable, Identifiable {
    let key: String
    let title: String
    let desc: String
    let icon: String
    let tint: String
    let ink: String

    var id: String { key }
    var tintColor: Color { Color(hex: tint) }
    var inkColor: Color { Color(hex: ink) }
    var iconName: String { String(icon.dropLast(4)) } // "ico_words.png" → "ico_words"
}

// MARK: - Activity

struct Activity: Codable, Sendable, Identifiable {
    let id: String
    let umbrella: String
    let name: String
    let desc: String
    let initials: String
    let tint: String
    let status: String
    let isNew: Bool?

    var tintColor: Color { Color(hex: tint) }
    var isLive: Bool { status == "live" }
    var isStub: Bool { status == "stub" }
    var showNewBadge: Bool { isNew == true }
}

// MARK: - Seed data loader

enum SeedData {
    static func loadCatalog() -> Catalog {
        guard let url = Bundle.main.url(forResource: "activities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(Catalog.self, from: data) else {
            fatalError("Could not load activities.json from bundle")
        }
        return catalog
    }
}
