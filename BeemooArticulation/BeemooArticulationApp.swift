import SwiftUI
import UIKit

@main
struct BeemooArticulationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var apiClient = APIClient()
    @State private var trialLogger = TrialLogger()
    @State private var runnerSettings = RunnerSettings()
    @State private var sProgressStore = SProgressStore()

    @State private var appReady = false
    @State private var loadingStatus = "Starting up..."

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appReady {
                    ContentView()
                        .environment(apiClient)
                        .environment(trialLogger)
                        .environment(runnerSettings)
                        .environment(sProgressStore)
                        .transition(.opacity)
                }

                if !appReady {
                    SplashScreen(status: loadingStatus)
                }
            }
            .animation(.easeOut(duration: 0.4), value: appReady)
            .task {
                // Check backend connectivity
                loadingStatus = "Connecting to server..."
                let reachable = await checkBackend()

                if reachable {
                    loadingStatus = "Ready!"
                } else {
                    loadingStatus = "Could not reach server. Check WiFi."
                    // Wait a bit then show the app anyway (bundle data still works)
                    try? await Task.sleep(for: .milliseconds(2000))
                }

                withAnimation {
                    appReady = true
                }
            }
        }
    }

    private func checkBackend() async -> Bool {
        let url = apiClient.baseURL
        for attempt in 0..<5 {
            if attempt > 0 {
                loadingStatus = "Connecting to server (attempt \(attempt + 1))..."
                try? await Task.sleep(for: .milliseconds(1000))
            }
            do {
                let (_, response) = try await URLSession.shared.data(from: url)
                if let http = response as? HTTPURLResponse, http.statusCode < 500 {
                    return true
                }
            } catch {
                continue
            }
        }
        return false
    }
}
