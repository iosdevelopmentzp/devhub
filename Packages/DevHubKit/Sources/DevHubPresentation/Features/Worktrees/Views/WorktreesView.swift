import SwiftUI
import DevHubDomain
import DevHubUI

struct WorktreesView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(BuildStore.self) private var build
    @Environment(ConfigActionsStore.self) private var configActions

    @State private var confirmingDeleteID: Worktree.ID?
    @State private var launchID: Worktree.ID?
    @State private var isConfirmingClean = false
    @State private var isCreating = false

    private var visible: [Worktree] {
        worktrees.worktrees.filter { session.matchesSearch($0.displayName, $0.path, $0.lastCommit) }
    }

    private var sections: [WorktreeSectionModel] {
        WorktreeSectionsMapper.sections(for: visible, rowModel: rowModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            WorktreesToolbar(isConfirmingClean: $isConfirmingClean, isCreating: $isCreating)

            Divider()

            content
        }
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: confirmingDeleteID)
        .animation(.snappy(duration: 0.18), value: isConfirmingClean)
        .animation(.snappy(duration: 0.18), value: isCreating)
    }

    private var content: some View {
        ListState(
            failure: worktrees.worktrees.isEmpty ? worktrees.error.map { error in
                ListMessage.failure("Cannot read worktrees", description: error) {
                    Task { await worktrees.refresh() }
                }
            } : nil,
            isLoading: worktrees.worktrees.isEmpty && worktrees.isLoading,
            loadingTitle: "Reading worktrees…",
            empty: nil,
            noResultsFor: visible.isEmpty ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sections) { section in
                        ListSectionHeader(section.title)
                        ForEach(section.rows) { model in
                            WorktreeRow(
                                model: model,
                                isConfirmingDelete: confirmingDeleteID == model.id,
                                isPickingLaunch: launchID == model.id,
                                onRequestDelete: {
                                    launchID = nil
                                    confirmingDeleteID = model.id
                                },
                                onCancelDelete: { confirmingDeleteID = nil },
                                onConfirmDelete: { deleteDerivedData, deleteBranch in
                                    confirmingDeleteID = nil
                                    worktrees.delete(id: model.id, deleteDerivedData: deleteDerivedData, deleteBranch: deleteBranch)
                                },
                                onBootstrap: { worktrees.bootstrap(id: model.id) },
                                onRequestLaunch: {
                                    confirmingDeleteID = nil
                                    launchID = model.id
                                },
                                onCancelLaunch: { launchID = nil },
                                onConfigAction: { runConfigAction($0, for: model) }
                            )
                            if let pending = configActions.pending(in: Placement.worktreesRow.slot(for: model.path)) {
                                ConfigActionPrompt(pending: pending)
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 8)
                            }
                            if model.id != section.rows.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func rowModel(for worktree: Worktree) -> WorktreeRowModel {
        WorktreeRowMapper.model(
            for: worktree,
            baseBranch: worktrees.baseBranch,
            mainCheckoutPath: worktrees.mainWorktree?.path,
            derivedDataSize: worktrees.derivedDataSizes[worktree.id],
            isBusy: worktrees.busyIDs.contains(worktree.id),
            isBootstrapping: worktrees.bootstrappingIDs.contains(worktree.id),
            isBuildSource: build.sourceWorktreeID == worktree.id,
            buildIsRunning: build.isRunning,
            configActions: rowActions
        )
    }

    private var rowActions: [ConfigActionItemModel] {
        ConfigActionItemMapper.models(for: configActions.actions(for: .worktreesRow), isRunning: configActions.isRunning)
    }

    private func runConfigAction(_ id: String, for model: WorktreeRowModel) {
        configActions.request(
            id: id,
            item: ActionItemContext(branch: model.branch, worktreePath: model.path, rowID: model.path),
            slot: Placement.worktreesRow.slot(for: model.path)
        )
    }
}

#Preview {
    WorktreesView()
        .previewEnvironment()
}
