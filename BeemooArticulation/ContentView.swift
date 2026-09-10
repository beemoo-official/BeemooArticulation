import SwiftUI

struct ContentView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .toolbar(.hidden)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .umbrella(let key):
                        ActivityListView(umbrellaKey: key, path: $path)
                            .toolbar(.hidden)
                    default:
                        Text("Coming soon")
                    }
                }
        }
        .tint(.bmNavy)
    }
}

#Preview {
    ContentView()
        .environment(APIClient())
}
