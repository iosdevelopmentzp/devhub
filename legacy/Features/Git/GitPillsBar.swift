import SwiftUI

struct GitPillsBar: View {
    @Environment(GitStore.self) private var store
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner

    private static let slot = "git.pills"

    private var status: GitStatus { store.status }

    private var isDetached: Bool { status.branch == nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                ActionBar(items: items)
                    .frame(maxWidth: .infinity, alignment: .leading)
                rightIcons
            }
            if let confirmation = store.confirmation, let text = confirmText(confirmation) {
                InlineConfirm(
                    text: text.message,
                    confirmTitle: text.button,
                    tint: .red,
                    onCancel: { store.cancelConfirmation() },
                    onConfirm: { Task { await store.confirm() } }
                )
            }
            ConfigActionResults(placement: .gitPills, slot: Self.slot, showsResults: true)
        }
    }

    private var rightIcons: some View {
        HStack(spacing: 2) {
            IconButton(systemImage: "terminal", help: "Open Terminal in this checkout") { store.openTerminal() }
            IconButton(systemImage: "arrow.triangle.pull", help: "Open a new pull or merge request on the web") {
                if let branch = status.branch { store.openNewRequest(branch: branch) }
            }
            IconButton(systemImage: "safari", help: "Open this branch on the web") {
                if let branch = status.branch { store.openOnWeb(branch: branch) }
            }
        }
    }

    private var items: [ActionItem] {
        let busy = store.isBusy
        let base = store.baseBranch
        var list = [
            ActionItem("Fetch", systemImage: "arrow.down.circle", hint: "git fetch origin", priority: 2, isDisabled: busy) {
                Task { await store.fetch() }
            },
            ActionItem("Pull", systemImage: "arrow.down", hint: "git pull --ff-only", priority: 4, isDisabled: busy || isDetached || status.upstream == nil || status.behind == 0) {
                Task { await store.pull() }
            },
            ActionItem("Push", systemImage: "arrow.up", hint: status.upstream == nil ? "git push -u origin \(status.branch ?? "")" : "git push", priority: 5, isDisabled: busy || isDetached || (status.upstream != nil && status.ahead == 0)) {
                Task { await store.push() }
            },
            ActionItem("Force Push…", systemImage: "arrow.up.to.line", hint: "git push --force-with-lease", priority: 1, isDisabled: busy || isDetached || status.upstream == nil) {
                store.askForcePush()
            },
            ActionItem("Rebase on \(store.baseLocalName)…", systemImage: "arrow.triangle.merge", hint: "git fetch, then git rebase --autostash \(base)", priority: 3, isDisabled: busy || isDetached) {
                store.askRebase()
            },
            ActionItem("Update \(store.baseLocalName)", systemImage: "arrow.down.to.line", hint: "Fast-forward \(store.baseLocalName) from origin without switching", priority: 3, isDisabled: busy) {
                Task { await store.updateBase() }
            },
            ActionItem("Stash", systemImage: "tray.and.arrow.down", hint: "git stash push --include-untracked", priority: 1, isDisabled: busy || status.isClean) {
                Task { await store.stash() }
            }
        ]
        if store.details.stashCount > 0 {
            list.append(ActionItem("Pop Stash", systemImage: "tray.and.arrow.up", hint: "git stash pop", priority: 2, isDisabled: busy) {
                Task { await store.popStash() }
            })
        }
        return list + configItems
    }

    private var configItems: [ActionItem] {
        let item = ActionItemContext(branch: status.branch, worktreePath: store.checkoutPath)
        return catalog.actions(for: .gitPills).map { action in
            ActionItem(action.title, systemImage: action.systemImage, hint: action.subtitle.isEmpty ? action.title : action.subtitle, priority: 1, isDisabled: action.isRunnable == false || runner.isRunning(action)) {
                runner.request(action, item: item, slot: Self.slot)
            }
        }
    }

    private func confirmText(_ confirmation: GitConfirmation) -> (message: String, button: String)? {
        switch confirmation {
        case .forcePush:
            ("Force push \(status.branch ?? "") with --force-with-lease? Remote commits you have not fetched are kept safe, others are overwritten.", "Force Push")
        case .rebase:
            ("Fetch, then rebase \(status.branch ?? "") on \(store.baseBranch) with --autostash? This rewrites your commits.", "Rebase")
        case .discard, .deleteBranch:
            nil
        }
    }
}

#Preview {
    GitPillsBar()
        .padding()
        .previewEnvironment()
}
