import SwiftUI
import DevHubUI

struct TicketLinkRow: View {
    let model: TicketLinkModel

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
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
        }
    }
}

#Preview {
    TicketLinkRow(model: .preview)
        .padding()
}
