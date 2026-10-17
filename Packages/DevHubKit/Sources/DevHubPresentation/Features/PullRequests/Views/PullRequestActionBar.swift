import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestActionBar: View {
    @Environment(AppActions.self) private var appActions

    let model: PullRequestRowModel
    let isPickingLaunch: Bool
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onAction: (PullRequestActionModel.Kind) -> Void
    let onMerge: (_ kind: PullRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void
    let onFixThreads: () -> Void

    @State private var confirmingMerge: PullRequestActionModel.Kind?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                ActionBar(items: items)
                    .disabled(model.isBusy)
                Spacer(minLength: 0)
                OverflowMenu {
                    PullRequestMenuItems(model: model, actions: model.actions, onPerform: perform, onFixThreads: onFixThreads)
                }
            }
            .controlSize(.regular)
            if let kind = confirmingMerge {
                MergeConfirmation(kind: kind, model: model, onCancel: { confirmingMerge = nil }) { kind, squash, remove in
                    confirmingMerge = nil
                    onMerge(kind, squash, remove)
                }
            }
            if isPickingLaunch {
                LaunchPicker(subject: model.sourceBranch, onCancel: onCancelLaunch, onRun: { appActions.buildAndRun(branch: remoteBranch, on: $0) })
            }
        }
        .animation(.snappy(duration: 0.18), value: confirmingMerge)
    }

    private var items: [ActionItem] {
        var items = model.primaryActions.enumerated().map { offset, action in
            ActionItem(action.title, systemImage: action.systemImage, hint: action.hint, priority: 10 - offset, isDisabled: false, tint: action.tint?.color) {
                perform(action.id)
            }
        }
        items.append(ActionItem("Build & Run", systemImage: "play.fill", hint: "Choose the simulator, environment and device ID, then build the source branch (uses or creates a worktree)", priority: 6, isDisabled: model.canCheckOut == false, tint: .green, action: onRequestLaunch))
        if let path = model.worktreePath {
            items.append(ActionItem("Terminal", systemImage: "terminal", hint: "Open the worktree of the source branch in Terminal", priority: 4, isDisabled: false) {
                appActions.openTerminal(at: path)
            })
        } else {
            items.append(ActionItem("Worktree", systemImage: "plus.rectangle.on.folder", hint: "Create a worktree for the source branch", priority: 3, isDisabled: model.canCreateWorktree == false) {
                appActions.createWorktree(branch: remoteBranch)
            })
        }
        items.append(ActionItem("GitLab", systemImage: "globe", hint: "Open in GitLab", priority: 5, isDisabled: model.webURL == nil) {
            appActions.open(model.webURL)
        })
        return items
    }

    private var remoteBranch: String {
        appActions.remoteRef(for: model.sourceBranch)
    }

    private func perform(_ kind: PullRequestActionModel.Kind) {
        guard kind != .merge, kind != .mergeWhenPipelinePasses else {
            confirmingMerge = kind
            return
        }
        onAction(kind)
    }
}

#Preview {
    PullRequestActionBar(model: .preview, isPickingLaunch: false, onRequestLaunch: {}, onCancelLaunch: {}, onAction: { _ in }, onMerge: { _, _, _ in }, onFixThreads: {})
        .previewEnvironment()
        .padding()
        .frame(width: 560)
}
