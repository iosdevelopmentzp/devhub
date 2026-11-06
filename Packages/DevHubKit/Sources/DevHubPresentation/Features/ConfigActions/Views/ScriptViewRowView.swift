import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptViewRowView: View {
    @Environment(ConfigActionsStore.self) private var store

    let parent: ResolvedAction
    let row: ScriptViewRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .hintWhenTruncated(row.title)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .hintWhenTruncated(subtitle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(row.tags ?? [], id: \.self) { tag in
                    ModelTag(model: ConfigTagMapper.model(tag))
                }
                ForEach(Array((row.actions ?? []).enumerated()), id: \.offset) { index, rowAction in
                    Button(rowAction.title) {
                        request(rowAction, index: index)
                    }
                    .controlSize(.small)
                    .fixedSize()
                }
            }
            if let pending = store.pending(in: slot) {
                ConfigActionPrompt(pending: pending)
            }
        }
    }

    private var slot: String {
        "view:\(parent.id)#\(row.id)"
    }

    private func request(_ rowAction: ScriptViewAction, index: Int) {
        let config = ActionConfig(id: "\(parent.id)#\(row.id)#\(index)", title: rowAction.title, run: rowAction.run, confirm: rowAction.confirm)
        store.request(ResolvedAction(config: config, origin: parent.origin), item: ActionItemContext(rowID: row.id), slot: slot)
    }
}

#Preview {
    ScriptViewRowView(
        parent: ResolvedAction(
            config: ActionConfig(id: "x", title: "Example", run: .open("x")),
            origin: ActionOrigin(layer: .project, directory: "/repo/.devhub", fileName: "actions/x.json", isHeaderScript: false, isExecutable: true)
        ),
        row: ScriptViewRow(id: "1", title: "Device A", subtitle: "iOS 26", tags: [ScriptViewTag(text: "ok", tint: .green)])
    )
    .padding()
    .previewEnvironment()
}
