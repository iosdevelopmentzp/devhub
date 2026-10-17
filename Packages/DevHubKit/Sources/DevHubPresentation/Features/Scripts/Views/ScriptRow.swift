import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptRow<Details: View>: View {
    let model: ScriptRowModel
    let onRun: () -> Void
    let onStop: () -> Void
    let onEdit: (String) -> Void
    let onReveal: (String) -> Void
    @ViewBuilder let details: () -> Details

    var body: some View {
        RowContainer { isHovered in
            VStack(alignment: .leading, spacing: 6) {
                row(isHovered: isHovered)
                details()
                    .padding(.leading, 42)
            }
        }
        .contextMenu {
            menuItems
        }
    }

    private func row(isHovered: Bool) -> some View {
        HStack(spacing: 10) {
            IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .hintWhenTruncated(model.title)
                    ForEach(model.tags, id: \.self) { tag in
                        ModelTag(model: tag)
                    }
                }
                if model.subtitle.isEmpty == false {
                    Text(model.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .hintWhenTruncated(model.subtitle)
                }
                FlowLayout(spacing: 6, lineSpacing: 2) {
                    Text(model.fileName)
                        .font(.caption2.monospaced())
                    Text("·")
                    Text(model.lastRunText)
                    if let blocked = model.blockedTag {
                        ModelTag(model: blocked)
                            .copyOnClick(model.chmodCommand, label: "chmod command")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Group {
                if model.isRunning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                        IconButton(systemImage: "stop.fill", help: "Stop the script", tint: .red, action: onStop)
                    }
                } else {
                    Button("Run", systemImage: "play.fill", action: onRun)
                        .buttonStyle(.bordered)
                        .disabled(model.isRunnable == false)
                        .fixedSize()
                }
            }
            .controlSize(.small)

            OverflowMenu {
                menuItems
            }
            .opacity(isHovered ? 1 : 0)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        if let path = model.scriptPath {
            Button(model.editTitle, systemImage: "pencil") {
                onEdit(path)
            }
            Button("Reveal in Finder", systemImage: "folder") {
                onReveal(path)
            }
        }
        if model.isRunnable == false {
            Button("Copy chmod Command", systemImage: "doc.on.doc") {}
                .copyOnClick(model.chmodCommand, label: "chmod command")
        }
    }
}

#Preview {
    ScriptRow(model: .preview, onRun: {}, onStop: {}, onEdit: { _ in }, onReveal: { _ in }) {
        EmptyView()
    }
    .previewEnvironment()
}
