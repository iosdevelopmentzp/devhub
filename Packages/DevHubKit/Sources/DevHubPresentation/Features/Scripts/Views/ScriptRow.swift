import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptRow<Details: View>: View {
    @Environment(\.copyToPasteboard) private var copyToPasteboard

    let model: ScriptRowModel
    let onRun: () -> Void
    let onStop: () -> Void
    let onEdit: (String) -> Void
    let onReveal: (String) -> Void
    let ordering: ScriptRowOrdering?
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

            if let ordering {
                IconButton(
                    systemImage: model.isFavorite ? "star.fill" : "star",
                    help: model.isFavorite ? "Remove from favorites" : "Add to favorites: favorites stay at the top",
                    tint: model.isFavorite ? .yellow : .secondary,
                    action: ordering.onToggleFavorite
                )
                .opacity(isHovered || model.isFavorite ? 1 : 0)
            }

            OverflowMenu {
                menuItems
            }
            .opacity(isHovered ? 1 : 0)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        if let ordering {
            Button(model.isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: model.isFavorite ? "star.slash" : "star", action: ordering.onToggleFavorite)
            if let onMoveUp = ordering.onMoveUp {
                Button("Move Up", systemImage: "arrow.up", action: onMoveUp)
            }
            if let onMoveDown = ordering.onMoveDown {
                Button("Move Down", systemImage: "arrow.down", action: onMoveDown)
            }
            Divider()
        }
        if let path = model.scriptPath {
            Button(model.editTitle, systemImage: "pencil") {
                onEdit(path)
            }
            Button("Reveal in Finder", systemImage: "folder") {
                onReveal(path)
            }
        }
        if model.isRunnable == false {
            Button("Copy chmod Command", systemImage: "doc.on.doc") {
                copyToPasteboard(model.chmodCommand, "chmod command")
            }
        }
    }
}

#Preview {
    ScriptRow(model: .preview, onRun: {}, onStop: {}, onEdit: { _ in }, onReveal: { _ in }, ordering: ScriptRowOrdering(onToggleFavorite: {}, onMoveUp: nil, onMoveDown: {})) {
        EmptyView()
    }
    .previewEnvironment()
}
