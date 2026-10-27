#if DEBUG
import Foundation
import DevHubPresentation

@MainActor
enum DebugLaunch {
    static func apply(assembly: PresentationAssembly, windows: AppWindows) {
        let environment = ProcessInfo.processInfo.environment
        if let mode = environment["DEVHUB_WINDOW_MODE"] {
            assembly.debugSetWindowMode(mode)
        }
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
        if let target = environment["DEVHUB_BUILD_RUN"] {
            Task {
                await assembly.debugBuildRun(target: target, profile: environment["DEVHUB_BUILD_PROFILE"], identity: environment["DEVHUB_LAUNCH_ID"], branch: environment["DEVHUB_BUILD_BRANCH"])
            }
        }
        if let mocks = environment["DEVHUB_MOCK"] {
            Task {
                await assembly.debugApplyMocks(mocks)
            }
        }
        if let streams = environment["DEVHUB_LOG_STREAMS"] {
            Task {
                await assembly.debugStreamLogs(streams.split(separator: ",").map(String.init))
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
        if let query = environment["DEVHUB_PALETTE"] {
            assembly.debugOpenPalette(query: query)
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
