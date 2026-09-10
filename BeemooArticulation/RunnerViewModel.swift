import SwiftUI

@Observable
final class RunnerViewModel {
    let config: ActivityConfig
    private(set) var currentIndex: Int = 0
    var isFinished: Bool = false

    var currentScreen: ScreenConfig {
        config.screens[currentIndex]
    }

    var screenCount: Int {
        config.screens.count
    }

    var progress: Double {
        guard screenCount > 0 else { return 0 }
        return Double(currentIndex) / Double(screenCount)
    }

    init(config: ActivityConfig) {
        self.config = config
    }

    func advance() {
        if currentIndex < config.screens.count - 1 {
            currentIndex += 1
        } else {
            isFinished = true
        }
    }
}
