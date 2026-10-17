import Foundation

extension ActionRunner {
    func handle(_ line: String, state: RunState, action: CatalogAction) {
        switch ScriptDirectiveParser.parse(line) {
        case .plain, .unknown:
            return
        case let .invalid(reason):
            activity.log("\(action.title): bad directive", detail: reason, outcome: .failure)
        case let .directives(directives):
            for directive in directives {
                apply(directive, state: state, action: action)
            }
        }
    }

    private func apply(_ directive: ScriptDirective, state: RunState, action: CatalogAction) {
        switch directive {
        case let .progress(text, fraction):
            setProgress(ActionProgress(actionID: action.id, actionTitle: action.title, text: text, fraction: fraction))
        case let .toast(text):
            toaster.show(text, tint: .green)
        case let .copy(text):
            toaster.copy(text, label: String(text.prefix(40)))
        case let .open(target):
            projectActions.open(target, title: action.title)
        case let .notify(title, body):
            activity.log(title, detail: body ?? action.title, outcome: .info)
        case let .refresh(targets):
            state.refresh.formUnion(targets)
        case let .error(message):
            state.error = message
        case .app:
            break
        case let .view(view):
            state.view = view
            setResult(ActionResult(status: .running, startedAt: results[action.id]?.startedAt ?? Date(), view: view), for: action.id)
        }
    }
}
