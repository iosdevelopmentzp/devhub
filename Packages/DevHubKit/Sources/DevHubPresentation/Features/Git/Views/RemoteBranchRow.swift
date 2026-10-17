import SwiftUI
import DevHubDomain
import DevHubUI

struct RemoteBranchRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: RemoteBranchRowModel
    let onCheckOut: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 7) { isHovered in
            row(isHovered: isHovered)
        }
        .contextMenu {
            Button("Check Out", systemImage: "arrow.right.circle") { onCheckOut() }
            Button("Build & Run on Target", systemImage: "play.fill") { appActions.buildAndRun(branch: model.remoteName) }
            Button("Create Worktree", systemImage: "plus.rectangle.on.folder") { appActions.createWorktree(branch: model.remoteName) }
            Divider()
            Button("Copy Name", systemImage: "doc.on.doc") { toaster.copy(model.localName) }
            Button("Open on Web", systemImage: "globe") { appActions.openBranchOnWeb(model.remoteName) }
            if let mergeRequest = model.mergeRequest {
                Button("Show Merge Request", systemImage: "arrow.triangle.pull") { appActions.showMergeRequest(iid: mergeRequest.iid) }
                Button("Open Merge Request in GitLab", systemImage: "globe") { appActions.open(mergeRequest.webURL) }
                Button("Copy Link with Title", systemImage: "text.bubble") { toaster.copy(mergeRequest.linkText, label: "Link with title") }
            } else {
                Button("New Merge Request", systemImage: "arrow.triangle.pull") { appActions.openNewMergeRequest(for: model.remoteName) }
            }
        }
    }

    private func row(isHovered: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "icloud")
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .padding(.top, 2)
                .hint("Branch on origin")
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(model.localName)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(model.localName, label: model.localName)
                    ForEach(model.tags, id: \.self) { tag in
                        ModelTag(model: tag)
                    }
                    if let mergeRequest = model.mergeRequest {
                        BranchMergeRequestTags(model: mergeRequest)
                    }
                    if let ticket = model.ticket {
                        TicketChip(model: ticket)
                    }
                }
                HStack(spacing: 6) {
                    if let dateText = model.dateText {
                        Text(dateText)
                            .font(.caption2.weight(.medium))
                    }
                    Text(model.author)
                        .font(.caption2)
                    Text(model.subject)
                        .font(.caption2)
                        .lineLimit(1)
                        .copyOnClick(model.subject, label: model.subject)
                }
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            HStack(spacing: 2) {
                IconButton(systemImage: "arrow.right.circle", help: model.checkOutHint) {
                    onCheckOut()
                }
                IconButton(systemImage: "play.fill", help: "Build & Run this branch on the target simulator (uses or creates a worktree)", tint: .green) {
                    appActions.buildAndRun(branch: model.remoteName)
                }
                .disabled(model.canBuild == false)
                IconButton(systemImage: "plus.rectangle.on.folder", help: "Create a worktree for this branch") {
                    appActions.createWorktree(branch: model.remoteName)
                }
                .disabled(model.canCreateWorktree == false)
                IconButton(systemImage: "globe", help: "Open on the web") {
                    appActions.openBranchOnWeb(model.remoteName)
                }
            }
            .opacity(isHovered ? 1 : 0)
            .disabled(model.areActionsEnabled == false)
        }
    }
}

#Preview {
    RemoteBranchRow(model: .preview, onCheckOut: {})
        .previewEnvironment()
}
