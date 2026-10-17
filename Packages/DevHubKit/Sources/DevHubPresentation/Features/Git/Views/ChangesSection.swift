import SwiftUI
import DevHubDomain
import DevHubUI

struct ChangesSection: View {
    @Environment(GitChangesStore.self) private var changes
    @Environment(GitStore.self) private var git
    @Environment(ProjectSession.self) private var session
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        VStack(spacing: 0) {
            CommitBox()
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task(id: "\(git.checkoutPath)#\(openCount)") {
            await changes.refresh()
        }
    }

    private var content: some View {
        ListState(
            failure: changes.changes.isEmpty ? changes.error.map { error in
                ListMessage.failure("Cannot read changes", description: error, actionTitle: nil)
            } : nil,
            isLoading: changes.changes.isEmpty && changes.isLoading,
            loadingTitle: "Reading changes…",
            empty: changes.changes.isEmpty
                ? ListMessage("No local changes", systemImage: "checkmark.circle", description: "The working tree of this checkout is clean.")
                : nil,
            noResultsFor: nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groups) { group in
                        groupView(group)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var groups: [FileChangeGroupModel] {
        FileChangeGroupMapper.groups(
            for: changes.changes,
            isVisible: { session.matchesSearch($0.path) },
            isBusy: changes.busyTitle != nil
        )
    }

    @ViewBuilder
    private func groupView(_ group: FileChangeGroupModel) -> some View {
        ListSectionHeader(group.title) {
            if let action = group.action {
                Button(action.title) { perform(action.kind) }
                    .buttonStyle(LinkButtonStyle(.accent))
                    .disabled(group.isActionEnabled == false)
            }
        }
        ForEach(group.changes) { change in
            FileChangeRow(
                model: rowModel(change),
                onToggleDiff: { changes.toggleDiff(change) },
                onStage: { changes.stage(change) },
                onUnstage: { changes.unstage(change) },
                onDiscard: { changes.discard(change) }
            )
        }
    }

    private func rowModel(_ change: GitFileChange) -> FileChangeRowModel {
        FileChangeRowMapper.model(
            for: change,
            checkoutPath: git.checkoutPath,
            isExpanded: changes.expandedIDs.contains(change.id),
            diff: changes.diffs[change.id],
            isBusy: changes.busyTitle != nil
        )
    }

    private func perform(_ kind: GroupAction.Kind) {
        switch kind {
        case .stageAll:
            changes.stageAll()
        case .unstageAll:
            changes.unstageAll()
        }
    }
}

#Preview {
    ChangesSection()
        .previewEnvironment()
}
