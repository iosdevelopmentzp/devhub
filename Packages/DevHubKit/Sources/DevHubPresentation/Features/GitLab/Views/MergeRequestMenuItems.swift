import SwiftUI
import DevHubDomain
import DevHubUI

struct MergeRequestMenuItems: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: MergeRequestRowModel
    let actions: [MergeRequestActionModel]
    let onPerform: (MergeRequestActionModel.Kind) -> Void
    let onFixThreads: () -> Void

    var body: some View {
        if model.canSwitchBranch {
            Button("Switch to Branch", systemImage: "arrow.triangle.swap") { appActions.switchToBranch(model.sourceBranch) }
        }
        if let path = model.worktreePath {
            Button("Open Worktree in Terminal", systemImage: "terminal") { appActions.openTerminal(at: path) }
            Button("Use This Checkout in Git Tab", systemImage: "arrow.triangle.branch") { appActions.useCheckoutInGitTab(path: path) }
        }
        ForEach(actions) { action in
            Button(action.title, systemImage: action.systemImage) { onPerform(action.id) }
        }
        Button("Copy Link", systemImage: "link") {
            guard let url = model.webURL else { return }
            toaster.copy(url.absoluteString, label: model.reference)
        }
        .disabled(model.webURL == nil)
        Button("Copy Link with Title", systemImage: "text.bubble") { toaster.copy(model.linkText, label: "Link with title") }
        Button("Copy Branch Name", systemImage: "doc.on.doc") { toaster.copy(model.sourceBranch) }
        if model.canFixThreads {
            Button("Fix Threads with Claude…", systemImage: "sparkles", action: onFixThreads)
        }
    }
}
