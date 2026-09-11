import SwiftUI

struct ContentView: View {
    @State private var selectedTab: BMTab = .home

    // Each tab owns an independent NavigationStack path
    @State private var homePath = NavigationPath()
    @State private var progressPath = NavigationPath()
    @State private var rewardsPath = NavigationPath()
    @State private var parentsPath = NavigationPath()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                homeTab.opacity(selectedTab == .home ? 1 : 0)
                progressTab.opacity(selectedTab == .progress ? 1 : 0)
                rewardsTab.opacity(selectedTab == .rewards ? 1 : 0)
                parentsTab.opacity(selectedTab == .parents ? 1 : 0)
            }

            BMTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Tab content

    private var homeTab: some View {
        NavigationStack(path: $homePath) {
            HomeView(path: $homePath, switchTab: $selectedTab)
                .toolbar(.hidden)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .umbrella(let key):
                        ActivityListView(umbrellaKey: key, path: $homePath)
                            .toolbar(.hidden)
                    default:
                        Text("Coming soon")
                    }
                }
        }
        .tint(.bmNavy)
    }

    private var progressTab: some View {
        NavigationStack(path: $progressPath) {
            ProgressTabView()
                .toolbar(.hidden)
        }
    }

    private var rewardsTab: some View {
        NavigationStack(path: $rewardsPath) {
            RewardsTabView()
                .toolbar(.hidden)
        }
    }

    private var parentsTab: some View {
        NavigationStack(path: $parentsPath) {
            ParentsListView()
                .toolbar(.hidden)
                .navigationDestination(for: ParentsRoute.self) { route in
                    switch route {
                    case .tips: TipsView()
                    case .settings: SettingsView()
                    case .switchChild: SwitchChildView()
                    case .subscription: Text("Subscription — coming soon")
                    }
                }
        }
        .tint(.bmNavy)
    }
}

enum ParentsRoute: Hashable {
    case tips, settings, switchChild, subscription
}

#Preview {
    ContentView()
        .environment(APIClient())
        .environment(TrialLogger())
        .environment(RunnerSettings())
}
