import SwiftUI
import DevHubDomain
import DevHubUI

struct InboxRow: View {
    @Environment(AppActions.self) private var appActions

    let model: InboxRowModel
    let onDone: () -> Void

    var body: some View {
        RowContainer(isHighlighted: false) { isHovered in
            HStack(alignment: .top, spacing: 10) {
                IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 28)
                    .hint(model.iconHint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(2)
                    if model.detail.isEmpty == false {
                        Text(model.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                if let dateText = model.dateText {
                    Text(dateText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                HoverActions(isVisible: isHovered, count: 3, spacing: 2) {
                    if let iid = model.pullRequestIID, let openHint = model.openHint {
                        IconButton(systemImage: "arrow.up.right", help: openHint) {
                            appActions.showPullRequest(iid: iid)
                        }
                    }
                    IconButton(systemImage: "safari", help: "Open in the browser") {
                        appActions.open(model.webURL)
                    }
                    .disabled(model.webURL == nil)
                    IconButton(systemImage: "checkmark", help: model.doneHint) {
                        onDone()
                    }
                    .disabled(model.isBusy)
                }
            }
        }
        .contextMenu {
            if let iid = model.pullRequestIID, let openHint = model.openHint {
                Button(openHint, systemImage: "arrow.up.right") { appActions.showPullRequest(iid: iid) }
            }
            Button("Open in Browser", systemImage: "safari") { appActions.open(model.webURL) }
                .disabled(model.webURL == nil)
            Button("Mark as Done", systemImage: "checkmark") { onDone() }
                .disabled(model.isBusy)
        }
    }
}

#Preview {
    InboxRow(model: .preview) {}
        .previewEnvironment()
}
