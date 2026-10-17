import SwiftUI
import DevHubDomain
import DevHubUI

struct OutputEntryView: View {
    let model: OutputEntryModel
    let onCopy: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                statusIcon
                Text(model.commandLine)
                    .font(.caption.monospaced().weight(.medium))
                    .lineLimit(model.isExpanded ? nil : 1)
                    .truncationMode(.middle)
                    .copyOnClick(model.command, label: "Command")
                Spacer(minLength: 6)
                if let folder = model.folder {
                    Text(folder)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: 160, alignment: .trailing)
                }
                Text(model.durationText)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                IconButton(systemImage: "doc.on.doc", help: "Copy command and output", action: onCopy)
                if model.canExpand {
                    IconButton(systemImage: model.expandIcon, help: model.expandHint, action: onToggle)
                }
            }
            if let output = model.output {
                Text(output)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(model.outputTint.map { $0.color.opacity(0.85) } ?? Color.primary.opacity(0.75))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 18)
            }
            if let error = model.error {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .padding(.leading, 18)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if model.isRunning {
            ProgressView()
                .controlSize(.mini)
                .frame(width: 12)
        } else {
            Image(systemName: model.statusIcon)
                .foregroundStyle(model.statusTint.color)
                .font(.caption)
                .hint(model.statusHint)
        }
    }
}

#Preview {
    OutputEntryView(model: .preview, onCopy: {}, onToggle: {})
        .previewEnvironment()
}
