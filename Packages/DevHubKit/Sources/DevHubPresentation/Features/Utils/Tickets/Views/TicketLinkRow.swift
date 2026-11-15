import SwiftUI
import DevHubUI

struct TicketLinkRow: View {
    @Environment(AppActions.self) private var appActions

    let model: TicketLinkModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let relation = model.relation {
                Text(relation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            ModelTag(model: model.statusTag)
            Text(model.key)
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)
                .copyOnClick(model.key, label: model.key)
            Text(model.summary)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .hintWhenTruncated(model.summary)
            if let url = model.url {
                Button {
                    appActions.open(url)
                } label: {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .hint("Open \(model.key) in the browser")
            }
        }
    }
}

#Preview {
    TicketLinkRow(model: .preview)
        .padding()
        .previewEnvironment()
}
