import SwiftUI
import DevHubDomain
import DevHubUI

struct TicketRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: TicketRowModel
    let onStart: () -> Void
    let onMove: (String) -> Void

    var body: some View {
        RowContainer { isHovered in
            HStack(alignment: .top, spacing: 10) {
                IconTile(systemImage: model.typeIcon, tint: model.typeTint.color, size: 32)
                    .hint(model.typeHint)
                details
                Spacer(minLength: 4)
                HoverActions(isVisible: isHovered, count: 3, spacing: 2) {
                    buttons
                }
            }
        }
        .contextMenu {
            menu
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(model.key)
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .copyOnClick(model.key, label: model.key)
                Text(model.summary)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .hintWhenTruncated(model.summary)
            }
            FlowLayout(spacing: 6) {
                ModelTag(model: model.statusTag)
                if let priority = model.priorityTag {
                    ModelTag(model: priority)
                }
                if let assignee = model.assignee {
                    PlainTag(assignee, systemImage: "person")
                }
                if let updated = model.updatedText {
                    Text(updated)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if model.isBusy {
            ProgressView()
                .controlSize(.small)
        } else {
            if model.canStart {
                IconButton(systemImage: "play.fill", help: "\(model.startTitle). jira issue move \(model.key)", tint: .blue, action: onStart)
            }
            IconButton(systemImage: "arrow.triangle.branch", help: "Copy the branch name \(model.branchName)") {
                toaster.copy(model.branchName, label: model.branchName)
            }
            IconButton(systemImage: "safari", help: "Open \(model.key) in the browser") {
                appActions.open(model.url)
            }
            .disabled(model.url == nil)
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button("Open in Browser", systemImage: "safari") { appActions.open(model.url) }
            .disabled(model.url == nil)
        Button("Copy Key", systemImage: "doc.on.doc") { toaster.copy(model.key, label: model.key) }
        Button("Copy Branch Name", systemImage: "arrow.triangle.branch") { toaster.copy(model.branchName, label: model.branchName) }
        if model.moveTargets.isEmpty == false {
            Divider()
            if model.canStart {
                Button(model.startTitle, systemImage: "play.fill", action: onStart)
            }
            Menu("Move to") {
                ForEach(model.moveTargets, id: \.self) { status in
                    Button(status) { onMove(status) }
                }
            }
        }
    }
}

#Preview {
    TicketRow(model: .preview, onStart: {}, onMove: { _ in })
        .previewEnvironment()
}
