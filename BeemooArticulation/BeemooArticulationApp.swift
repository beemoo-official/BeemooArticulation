import SwiftUI
import UIKit

@main
struct BeemooArticulationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var apiClient = APIClient()

    init() {
        #if DEBUG
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            if !names.isEmpty {
                print("Font family: \(family) → \(names)")
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(apiClient)
        }
    }
}
