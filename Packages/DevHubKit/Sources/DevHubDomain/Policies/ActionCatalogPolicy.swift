import Foundation

package enum ActionCatalogPolicy {
    package static func actions(for placement: Placement, resolved: ResolvedConfig, facts: ActionConditionFacts) -> [CatalogAction] {
        if placement == .homeQuickActions {
            return quickActions(resolved: resolved, facts: facts)
        }
        return resolved.actions.filter { action in
            if placement == .homeScripts, action.origin.isHeaderScript, action.origin.isExecutable == false {
                return true
            }
            return action.config.isPlaced(at: placement) && isVisible(action.config, facts: facts)
        }
        .map(CatalogAction.config)
    }

    package static func action(id: String, resolved: ResolvedConfig) -> CatalogAction? {
        if let builtin = BuiltinAction.named(id) {
            return .builtin(builtin)
        }
        return resolved.action(id: id).map(CatalogAction.config)
    }

    package static func isVisible(_ action: ActionConfig, facts: ActionConditionFacts) -> Bool {
        guard let condition = action.when else { return true }
        if let git = condition.git {
            guard let clean = facts.isGitClean, (git == "clean" && clean) || (git == "dirty" && clean == false) else { return false }
        }
        if let simulator = condition.simulator {
            guard simulator == "booted", facts.isTargetBooted else { return false }
        }
        if let tool = condition.tool, facts.installedTools.contains(tool) == false {
            return false
        }
        if let kind = condition.kind, kind != facts.kind {
            return false
        }
        if let host = condition.host, host != facts.hostKind {
            return false
        }
        return true
    }

    private static func quickActions(resolved: ResolvedConfig, facts: ActionConditionFacts) -> [CatalogAction] {
        if let listed = resolved.project.quickActionIDs {
            return listed.compactMap { id in
                guard let action = action(id: id, resolved: resolved) else { return nil }
                guard let config = action.resolved?.config else { return action }
                return isVisible(config, facts: facts) ? action : nil
            }
        }
        let placed = resolved.actions.filter { action in
            action.config.effectivePlacements.contains(.homeQuickActions) && isVisible(action.config, facts: facts)
        }
        return BuiltinAction.homeDefaults.map(CatalogAction.builtin) + placed.map(CatalogAction.config)
    }
}
