import Foundation
import DevHubDomain
import DevHubUI

extension ConfigActionsStore {
    func handle(_ line: String, action: ResolvedAction, outcome: inout ConfigActionOutcome) {
        switch ScriptDirectiveParser.parse(line) {
        case .plain, .unknown:
            return
        case let .invalid(reason):
            activity.log("\(action.config.title): bad directive", detail: reason, outcome: .failure)
        case let .directives(directives):
            for directive in directives {
                apply(directive, action: action, outcome: &outcome)
            }
        }
    }

    private func apply(_ directive: ScriptDirective, action: ResolvedAction, outcome: inout ConfigActionOutcome) {
        let title = action.config.title
        switch directive {
        case let .progress(text, fraction):
            setProgress(ConfigActionProgress(actionID: action.id, actionTitle: title, text: text, fraction: fraction))
        case let .toast(text):
            toaster.show(text)
        case let .copy(text):
            toaster.copy(text, label: text)
        case let .open(target):
            _ = workspace.openTarget(target, relativeTo: ProjectPath(session.selectedProject.path).expanded)
        case let .notify(notification, body):
            activity.log(notification, detail: body ?? title, outcome: .info)
        case let .refresh(targets):
            outcome.refresh.formUnion(targets)
        case let .error(message):
            outcome.error = message
        case .app, .state:
            break
        case let .view(view):
            outcome.view = view
            setRun(ConfigActionRun(status: .running, startedAt: runs[action.id]?.startedAt ?? Date(), view: view), for: action.id)
        }
    }
}
