import Foundation
import Observation

@MainActor
@Observable
final class ActionCatalog {
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let tools: ToolLocating

    init(config: ConfigStore, session: ProjectSession, settings: SettingsStore, tools: ToolLocating) {
        self.config = config
        self.session = session
        self.settings = settings
        self.tools = tools
    }

    func actions(for placement: Placement) -> [CatalogAction] {
        if placement == .homeQuickActions {
            return quickActions()
        }
        return configActions.filter { action in
            guard case let .config(resolved) = action.source else { return false }
            if placement == .homeScripts, resolved.origin.isHeaderScript, resolved.origin.isExecutable == false {
                return true
            }
            return resolved.config.isPlaced(at: placement) && isVisible(resolved.config)
        }
    }

    func action(id: String) -> CatalogAction? {
        if let builtin = BuiltinAction.named(id) {
            return builtinAction(builtin)
        }
        return config.resolved.action(id: id).map(CatalogAction.init(resolved:))
    }

    private var configActions: [CatalogAction] {
        config.resolved.actions.map(CatalogAction.init(resolved:))
    }

    private func quickActions() -> [CatalogAction] {
        if let listed = config.config.quickActionIDs {
            return listed.compactMap { id in
                guard let action = action(id: id) else { return nil }
                guard case let .config(resolved) = action.source else { return action }
                return isVisible(resolved.config) ? action : nil
            }
        }
        let builtins = BuiltinAction.allCases.map(builtinAction)
        let placed = configActions.filter { action in
            guard case let .config(resolved) = action.source else { return false }
            return resolved.config.effectivePlacements.contains(.homeQuickActions) && isVisible(resolved.config)
        }
        return builtins + placed
    }

    private func builtinAction(_ builtin: BuiltinAction) -> CatalogAction {
        let text = builtinText(builtin)
        return CatalogAction(builtin: builtin, title: text.title, subtitle: text.subtitle)
    }

    private func builtinText(_ builtin: BuiltinAction) -> (title: String, subtitle: String) {
        switch builtin {
        case .buildRun: ("Build & Run", config.effective?.scheme.map { "Scheme \($0)" } ?? "Build and launch")
        case .runAttach: ("Run & Attach", "Launch and attach the debugger")
        case .openEditor: ("Open in \(settings.editor.title)", "Project container")
        case .openFolder: ("Open folder", "Show in Finder")
        case .terminal: ("Terminal here", "Open \(settings.terminal.title)")
        case .copyBranch: ("Copy branch", session.branch ?? "No branch")
        case .repository: ("Repository", "Open the web page")
        case .newPullRequest: (session.repository?.host == .gitlab ? "New merge request" : "New pull request", "From the current branch")
        }
    }

    private func isVisible(_ action: ActionConfig) -> Bool {
        guard let condition = action.when else { return true }
        if let git = condition.git {
            let clean = session.summary.isClean
            guard (git == "clean" && clean) || (git == "dirty" && clean == false) else { return false }
        }
        if let simulator = condition.simulator {
            guard simulator == "booted", session.target?.isBooted == true else { return false }
        }
        if let tool = condition.tool, tools.isInstalled(tool) == false {
            return false
        }
        if let kind = condition.kind, kind != config.effective?.kind {
            return false
        }
        return true
    }
}
