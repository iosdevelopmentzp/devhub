import SwiftUI
import DevHubDomain
import DevHubUI

struct BuildSourceMenu: View {
    @Environment(BuildStore.self) private var build
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(ProjectSession.self) private var session
    @Environment(GitStore.self) private var git

    @State private var isPickingBranch = false

    var body: some View {
        let model = model
        Menu {
            Button(model.mainTitle) {
                build.useSource(worktreeID: nil)
            }
            if model.worktrees.isEmpty == false {
                Section(model.worktreesTitle) {
                    ForEach(model.worktrees) { worktree in
                        Button(worktree.title) {
                            build.useSource(worktreeID: worktree.path)
                        }
                    }
                }
            }
            Divider()
            Button(model.otherBranchTitle) {
                isPickingBranch = true
            }
        } label: {
            CheckoutBadge(model: badge)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .hint(badge.hint)
        .popover(isPresented: $isPickingBranch, arrowEdge: .bottom) {
            BranchPicker { name in
                build.useSource(branch: name)
                isPickingBranch = false
            }
            .environment(git)
        }
    }

    private var badge: CheckoutBadgeModel {
        CheckoutBadgeMapper.buildSource(
            build.source,
            label: build.sourceLabel,
            hasWorktree: build.sourceWorktreeID != nil,
            worktrees: worktrees.worktrees
        )
    }

    private var model: BuildSourceMenuModel {
        BuildSourceMenuMapper.model(worktrees: worktrees.worktrees, projectName: session.selectedProject.name)
    }
}

#Preview {
    BuildSourceMenu()
        .padding()
        .previewEnvironment()
}
