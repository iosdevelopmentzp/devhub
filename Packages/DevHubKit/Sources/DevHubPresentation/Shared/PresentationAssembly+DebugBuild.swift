#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugBuildRun(target: String, profile: String?, branch: String?) async {
        await worktrees.refresh()
        await simulators.refresh()
        await config.reload()
        await build.refreshSchemes()
        guard let simulator = simulators.all.first(where: { $0.id == target || $0.name == target }) else {
            activity.log("Debug build", detail: "No simulator \(target).", outcome: .failure)
            return
        }
        build.selectTarget(id: simulator.id)
        if let profile {
            build.setProfile(profile)
        }
        if let branch {
            build.useSource(branch: branch)
        }
        build.run()
        for _ in 0..<3_000 {
            try? await Task.sleep(for: .milliseconds(100))
            guard build.isRunning else { break }
        }
        activity.log("Debug build", detail: "Finished: \(build.state.phase)", outcome: .info)
    }
}
#endif
