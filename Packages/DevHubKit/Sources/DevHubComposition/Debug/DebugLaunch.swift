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
        let runs = (environment["DEVHUB_RUN_ACTION"] ?? "").split(separator: ",").map(String.init)
        let request = environment["DEVHUB_REQUEST_ACTION"]
        if runs.isEmpty == false || request != nil {
            Task {
                for id in runs {
                    await assembly.debugRunAction(id, prompt: false)
                }
                if let request {
                    await assembly.debugRunAction(request, prompt: true)
                }
            }
        }
        if let script = environment["DEVHUB_GIT_OPS"] {
            Task {
                await assembly.debugRunGitOps(script)
            }
        }
        guard environment["DEVHUB_OPEN_PANEL"] == "1" else { return }
        if let tab = environment["DEVHUB_TAB"] {
            assembly.debugShowTab(tab)
        }
        if environment["DEVHUB_SHOW_OUTPUT"] == "1" {
            assembly.debugShowOutput()
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
