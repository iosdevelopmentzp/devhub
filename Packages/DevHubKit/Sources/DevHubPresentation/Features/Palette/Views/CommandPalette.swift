import SwiftUI
import DevHubDomain
import DevHubUI

struct CommandPalette: View {
    @Environment(Navigator.self) private var navigator
    @Environment(AppActions.self) private var appActions
    @Environment(ConfigStore.self) private var config
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(BuildStore.self) private var build
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(AISessionsStore.self) private var sessions
    @Environment(KeepAwakeStore.self) private var keepAwake
    @Environment(\.codeHostWords) private var words

    let onClose: () -> Void

    @State private var highlighted = 0
    @FocusState private var isFocused: Bool

    private static let slot = "palette"

    var body: some View {
        @Bindable var navigator = navigator
        let query = navigator.paletteQuery
        let matches = PaletteMapper.matches(items, query: query)
        VStack(alignment: .leading, spacing: 0) {
            TextField("Type a tab, an action, a branch, a simulator…", text: $navigator.paletteQuery)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(12)
                .focused($isFocused)
                .onSubmit { run(matches) }
                .onKeyPress(.downArrow) {
                    highlighted = min(highlighted + 1, max(matches.count - 1, 0))
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    highlighted = max(highlighted - 1, 0)
                    return .handled
                }
                .onKeyPress(.escape) {
                    onClose()
                    return .handled
                }
                .onChange(of: navigator.paletteQuery) { highlighted = 0 }
            Divider()
            if let pending = configActions.pending(in: Self.slot) {
                ConfigActionPrompt(pending: pending)
                    .padding(12)
                Divider()
            }
            if matches.isEmpty {
                Text("Nothing matches “\(query)”")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(matches.enumerated()), id: \.element.id) { index, item in
                                PaletteRow(item: item, isHighlighted: index == highlighted) {
                                    perform(item)
                                }
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: highlighted) {
                        guard matches.indices.contains(highlighted) else { return }
                        proxy.scrollTo(matches[highlighted].id)
                    }
                }
            }
        }
        .frame(width: 520, height: 420, alignment: .top)
        .onAppear { isFocused = true }
    }

    private var items: [PaletteItem] {
        PaletteMapper.items(
            from: PaletteSources(
                tabs: TabItemMapper.items(customTabs: config.resolved.tabs, words: words),
                actions: paletteActions,
                simulators: simulators.all,
                targetID: build.target?.id,
                branches: git.state?.localBranches.map(\.name) ?? [],
                currentBranch: git.currentBranch,
                worktrees: worktrees.worktrees,
                pullRequests: pullRequests.requests,
                sessions: sessions.scoped,
                favoriteSessionIDs: sessions.favoriteIDs,
                isKeepAwakeOn: keepAwake.isActive,
                requestNumber: words.reference
            ),
            actionTitle: { QuickActionTileMapper.model(for: $0, scheme: configActions.effective.scheme, branch: git.currentBranch, words: words, isBuildRunning: build.isRunning, isRunning: false).title }
        )
    }

    private var paletteActions: [CatalogAction] {
        BuiltinAction.allCases.map(CatalogAction.builtin) + config.resolved.actions.filter { $0.origin.isExecutable }.map(CatalogAction.config).filter(configActions.isVisible)
    }

    private func run(_ matches: [PaletteItem]) {
        guard matches.indices.contains(highlighted) else { return }
        perform(matches[highlighted])
    }

    private func perform(_ item: PaletteItem) {
        switch item.command {
        case .showTab(let id):
            navigator.selection = id
        case .runAction(let action):
            switch action {
            case .builtin(let builtin):
                appActions.perform(builtin)
            case .config(let resolved):
                configActions.request(resolved, item: .none, slot: Self.slot)
                guard action.needsPrompt == false else { return }
            }
        case .selectTarget(let id):
            appActions.selectBuildTarget(id)
        case .buildAndRun(let id):
            appActions.buildAndRun(on: id)
        case .switchBranch(let branch):
            appActions.switchToBranch(branch)
        case .buildBranch(let branch):
            appActions.buildAndRun(branch: branch)
        case .createWorktree(let branch):
            appActions.createWorktree(branch: branch)
        case .buildWorktree(let id):
            appActions.buildAndRun(worktreeID: id)
        case .openFolder(let path):
            appActions.openInFinder(path: path)
        case .showPullRequest(let iid):
            appActions.showPullRequest(iid: iid)
        case let .resumeSession(command, folder, title):
            appActions.runInTerminal(command, at: folder, title: title)
        case .openSettings:
            appActions.openSettings()
        case .toggleKeepAwake:
            keepAwake.toggle()
        }
        onClose()
    }
}

#Preview {
    CommandPalette(onClose: {})
        .previewEnvironment()
}
