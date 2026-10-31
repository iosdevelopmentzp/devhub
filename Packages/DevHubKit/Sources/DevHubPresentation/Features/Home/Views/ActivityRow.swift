import SwiftUI
import DevHubDomain
import DevHubUI

struct ActivityRow: View {
    let model: ActivityRowModel
    let onOpen: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            StatusDot(color: model.dotTint.color.opacity(model.dotOpacity))
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.title)
                    .font(.callout)
                    .copyOnClick(model.title, label: model.title)
                if model.detail.isEmpty == false {
                    Text(model.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .copyOnClick(model.detail, label: model.detail)
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(model.dateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let kindTitle = model.kindTitle {
                    Text(kindTitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            if let openHint = model.openHint {
                IconButton(systemImage: "arrow.up.right", help: openHint, tint: .secondary) {
                    onOpen()
                }
                .padding(.top, -3)
            }
        }
        .contextMenu {
            if let openHint = model.openHint {
                Button(openHint, systemImage: "arrow.up.right") { onOpen() }
            }
        }
    }
}

#Preview {
    ActivityRow(model: .preview) {}
        .previewEnvironment()
}
