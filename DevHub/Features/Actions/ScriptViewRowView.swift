import SwiftUI

struct ScriptViewRowView: View {
    @Environment(ActionRunner.self) private var runner

    let parent: CatalogAction
    let row: ScriptViewRow

    private var slot: String { "view:\(parent.id)#\(row.id)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(row.tags ?? [], id: \.self) { tag in
                    Tag(tag.text, tint: tag.tint ?? .gray)
                }
                ForEach(Array((row.actions ?? []).enumerated()), id: \.offset) { index, rowAction in
                    Button(rowAction.title) { request(rowAction, index: index) }
                        .controlSize(.small)
                        .fixedSize()
                }
            }
            if let pending = runner.pending(in: slot) {
                ActionPrompt(pending: pending)
            }
        }
    }

    private func request(_ rowAction: ScriptViewAction, index: Int) {
        guard case let .config(resolved) = parent.source else { return }
        let config = ActionConfig(id: "\(parent.id)#\(row.id)#\(index)", title: rowAction.title, run: rowAction.run, confirm: rowAction.confirm)
        let action = CatalogAction(resolved: ResolvedAction(config: config, origin: resolved.origin))
        runner.request(action, item: ActionItemContext(rowID: row.id), slot: slot)
    }
}

#Preview {
    ScriptViewRowView(
        parent: CatalogAction(builtin: .openFolder, title: "Example", subtitle: ""),
        row: ScriptViewRow(id: "1", title: "Device A", subtitle: "iOS 26", tags: [ScriptViewTag(text: "ok", tint: .green)], actions: nil)
    )
    .padding()
    .previewEnvironment()
}
