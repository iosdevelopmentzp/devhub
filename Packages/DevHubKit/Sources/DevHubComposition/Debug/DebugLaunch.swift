#if DEBUG
import Foundation
import DevHubPresentation

@MainActor
enum DebugLaunch {
    static func apply(assembly: PresentationAssembly, windows: AppWindows) {
        let environment = ProcessInfo.processInfo.environment
        if let path = environment["DEVHUB_PROJECT"] {
            assembly.debugAddProject(path: path)
        }
        guard environment["DEVHUB_OPEN_PANEL"] == "1" else { return }
        if let tab = environment["DEVHUB_TAB"] {
            assembly.debugShowTab(tab)
        }
        let delay = Double(environment["DEVHUB_SNAPSHOT_DELAY"] ?? "") ?? 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            windows.debugShowPanel()
            guard let path = environment["DEVHUB_SNAPSHOT"] else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                windows.debugSnapshot(to: path)
            }
        }
    }
}
#endif
