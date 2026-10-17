import Testing
@testable import DevHubDomain

@Suite struct ActionCatalogPolicyTests {
    private let facts = ActionConditionFacts(isGitClean: true, isTargetBooted: false, installedTools: ["gh"], kind: .xcode)

    private func resolved(_ actions: [ActionConfig], quickActions: [String]? = nil) -> ResolvedConfig {
        let origin = ActionOrigin(layer: .project, directory: "/p/.devhub", fileName: "actions/a.json", isHeaderScript: false, isExecutable: true)
        return ResolvedConfig(
            project: ProjectConfig(home: quickActions.map { HomeConfig(quickActions: $0) }),
            actions: actions.map { ResolvedAction(config: $0, origin: origin) },
            tabs: [],
            issues: [],
            layers: []
        )
    }

    private func action(_ id: String, placements: [Placement]? = nil, when: ActionCondition? = nil) -> ActionConfig {
        ActionConfig(id: id, title: id, placements: placements, run: .open("x"), when: when)
    }

    @Test func actionsWithoutPlacementsGoToHomeScripts() {
        let config = resolved([action("a"), action("b", placements: [.gitPills])])

        #expect(ActionCatalogPolicy.actions(for: .homeScripts, resolved: config, facts: facts).map(\.id) == ["a"])
        #expect(ActionCatalogPolicy.actions(for: .gitPills, resolved: config, facts: facts).map(\.id) == ["b"])
    }

    @Test func thePaletteHoldsEveryAction() {
        let config = resolved([action("a"), action("b", placements: [.gitPills])])

        #expect(ActionCatalogPolicy.actions(for: .palette, resolved: config, facts: facts).map(\.id) == ["a", "b"])
    }

    @Test func conditionsHideActions() {
        let config = resolved([
            action("dirty", when: ActionCondition(git: "dirty")),
            action("booted", when: ActionCondition(simulator: "booted")),
            action("tool", when: ActionCondition(tool: "gh")),
            action("missing", when: ActionCondition(tool: "glab")),
            action("command", when: ActionCondition(kind: .command)),
        ])

        #expect(ActionCatalogPolicy.actions(for: .homeScripts, resolved: config, facts: facts).map(\.id) == ["tool"])
    }

    @Test func anUnknownGitStateHidesGitConditions() {
        let unknown = ActionConditionFacts(isGitClean: nil, isTargetBooted: false, installedTools: [], kind: nil)

        #expect(ActionCatalogPolicy.isVisible(action("x", when: ActionCondition(git: "clean")), facts: unknown) == false)
    }

    @Test func quickActionsFollowTheConfiguredOrder() {
        let config = resolved([action("clean", placements: [.gitPills])], quickActions: ["clean", "builtin.terminal", "gone"])

        #expect(ActionCatalogPolicy.actions(for: .homeQuickActions, resolved: config, facts: facts).map(\.id) == ["clean", "builtin.terminal"])
    }

    @Test func withoutAnOrderQuickActionsAreTheBuiltInsThenThePlacedOnes() {
        let config = resolved([action("pinned", placements: [.homeQuickActions]), action("other")])

        let ids = ActionCatalogPolicy.actions(for: .homeQuickActions, resolved: config, facts: facts).map(\.id)

        #expect(ids == BuiltinAction.allCases.map(\.id) + ["pinned"])
    }

    @Test func aBlockedHeaderScriptStaysOnHome() {
        let origin = ActionOrigin(layer: .project, directory: "/p/.devhub", fileName: "scripts/x.sh", isHeaderScript: true, isExecutable: false)
        let config = ResolvedConfig(project: .empty, actions: [ResolvedAction(config: action("script:x", placements: [.gitPills]), origin: origin)], tabs: [], issues: [], layers: [])

        let found = ActionCatalogPolicy.actions(for: .homeScripts, resolved: config, facts: facts)

        #expect(found.map(\.id) == ["script:x"])
        #expect(found.first?.isRunnable == false)
        #expect(found.first?.fileName == "x.sh")
    }

    @Test func actionLookupFindsBuiltInsAndConfig() {
        let config = resolved([action("a")])

        #expect(ActionCatalogPolicy.action(id: "builtin.buildRun", resolved: config) == .builtin(.buildRun))
        #expect(ActionCatalogPolicy.action(id: "a", resolved: config)?.id == "a")
        #expect(ActionCatalogPolicy.action(id: "none", resolved: config) == nil)
    }
}
