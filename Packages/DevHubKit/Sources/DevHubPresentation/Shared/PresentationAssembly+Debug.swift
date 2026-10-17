#if DEBUG
import Foundation
import DevHubDomain

package extension PresentationAssembly {
    func debugAddProject(path: String) {
        session.addProject(at: ProjectPath(path).url)
    }

    func debugShowTab(_ rawValue: String) {
        guard let feature = FeatureID(rawValue: rawValue) else { return }
        navigator.show(feature)
    }

    func debugShowOutput() {
        output.isVisible = true
    }

    func debugRunAction(_ id: String, prompt: Bool) async {
        await worktrees.refresh()
        await config.reload()
        guard let action = config.resolved.action(id: id) else {
            activity.log("Debug run", detail: "No action with id \(id).", outcome: .failure)
            return
        }
        if prompt {
            configActions.request(action, item: .none, slot: "home.scripts:\(action.id)")
        } else {
            configActions.runWithDefaults(action, item: .none)
        }
    }
}
#endif
