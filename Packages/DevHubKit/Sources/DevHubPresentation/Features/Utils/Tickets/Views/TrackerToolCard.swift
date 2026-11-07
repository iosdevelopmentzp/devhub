import SwiftUI
import DevHubDomain
import DevHubUI

struct TrackerToolCard: View {
    let model: TrackerToolModel
    let onCheckAgain: () -> Void

    var body: some View {
        HStack(alignment: model.isCompact ? .center : .top, spacing: 10) {
            icon
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.callout.weight(.semibold))
                if model.detail.isEmpty == false {
                    Text(model.detail)
                        .font(model.isCompact ? .caption.monospaced() : .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let command = model.command {
                    Text(command)
                        .font(.caption.monospaced())
                        .copyOnClick(command, label: "command")
                }
            }
            Spacer(minLength: 8)
            if model.showsCheckAgain {
                Button("Check Again", action: onCheckAgain)
                    .controlSize(.small)
                    .fixedSize()
                    .hint("Looks for jira, its config file and the API token again.")
            }
        }
        .padding(model.isCompact ? 8 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(model.tint.color.opacity(0.08))
        )
    }

    @ViewBuilder
    private var icon: some View {
        if model.isWorking {
            ProgressView()
                .controlSize(.small)
        } else {
            Image(systemName: model.icon)
                .foregroundStyle(model.tint.color)
        }
    }
}

#Preview {
    TrackerToolCard(model: .preview, onCheckAgain: {})
        .padding()
        .previewEnvironment()
}
