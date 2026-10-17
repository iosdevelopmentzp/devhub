import SwiftUI
import DevHubDomain
import DevHubUI

struct ActivityRow: View {
    let model: ActivityRowModel

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            StatusDot(color: model.dotTint.color.opacity(model.dotOpacity))
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.title)
                    .font(.callout)
                    .copyOnClick(model.title, label: model.title)
                Text(model.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .copyOnClick(model.detail, label: model.detail)
            }
            Spacer(minLength: 8)
            Text(model.dateText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ActivityRow(model: .preview)
        .previewEnvironment()
}
