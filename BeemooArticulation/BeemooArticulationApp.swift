import SwiftUI
import UIKit

@main
struct BeemooArticulationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var apiClient = APIClient()
    @State private var trialLogger = TrialLogger()
    @State private var runnerSettings = RunnerSettings()
    @State private var sProgressStore = SProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(apiClient)
                .environment(trialLogger)
                .environment(runnerSettings)
                .environment(sProgressStore)
        }
    }
}
