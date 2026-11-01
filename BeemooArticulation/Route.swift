import Foundation

enum Route: Hashable {
    case home
    case umbrella(key: String)
    case activity(id: String)
    case sPracticeHome
    case progress
    case rewards
    case tips
}
