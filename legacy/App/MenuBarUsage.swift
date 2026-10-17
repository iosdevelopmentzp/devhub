import Foundation
import Observation

@MainActor
enum MenuBarUsage {
    static func bind(usage: UsageStore, windows: AppWindows?) {
        guard let windows else { return }
        windows.setStatusTitle(usage.menuBarText)
        withObservationTracking {
            _ = usage.menuBarText
        } onChange: {
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    bind(usage: usage, windows: windows)
                }
            }
        }
    }
}
