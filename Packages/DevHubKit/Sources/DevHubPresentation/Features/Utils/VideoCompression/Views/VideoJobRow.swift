import SwiftUI
import DevHubDomain
import DevHubUI

struct VideoJobRow: View {
    let model: VideoJobRowModel
    let onStop: () -> Void
    let onRemove: () -> Void
    let onCompressAgain: () -> Void
    let onReveal: (String) -> Void
    let onOpen: (String) -> Void

    var body: some View {
        RowContainer { isHovered in
            HStack(alignment: .top, spacing: 10) {
                IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)
                details
                Spacer(minLength: 8)
                HoverActions(isVisible: isHovered, count: 3, spacing: 2) {
                    buttons
                }
            }
        }
        .contextMenu {
            menu
        }
        .onDrag {
            guard let path = model.resultPath else { return NSItemProvider() }
            return NSItemProvider(contentsOf: URL(fileURLWithPath: path)) ?? NSItemProvider()
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(model.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .hintWhenTruncated(model.title)
                ModelTag(model: model.qualityTag)
            }
            Text(model.facts)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if let progress = model.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .padding(.vertical, 2)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if model.isWorking {
                    ProgressView()
                        .controlSize(.mini)
                }
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(model.statusTint.color)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let name = model.resultName, let path = model.resultPath {
                Button(name) {
                    onReveal(path)
                }
                .buttonStyle(LinkButtonStyle(.accent))
                .font(.caption.monospaced())
                .hint("Show in Finder. Drag the row into a chat or a ticket to share the file.")
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        if model.canStop {
            IconButton(systemImage: "stop.fill", help: "Stop. No file is written.", tint: .red, action: onStop)
        }
        if let path = model.resultPath {
            IconButton(systemImage: "play.rectangle", help: "Open the result") { onOpen(path) }
            IconButton(systemImage: "folder", help: "Show the result in Finder") { onReveal(path) }
        }
        if model.canCompressAgain, model.resultPath == nil {
            IconButton(systemImage: "arrow.clockwise", help: "Compress again with the current quality", action: onCompressAgain)
        }
        if model.canRemove {
            IconButton(systemImage: "xmark", help: "Remove from the list. The files stay.", action: onRemove)
        }
    }

    @ViewBuilder
    private var menu: some View {
        if let path = model.resultPath {
            Button("Open the Result", systemImage: "play.rectangle") { onOpen(path) }
            Button("Show the Result in Finder", systemImage: "folder") { onReveal(path) }
        }
        Button("Show the Original in Finder", systemImage: "doc") { onReveal(model.source) }
        if model.canCompressAgain {
            Button("Compress Again", systemImage: "arrow.clockwise", action: onCompressAgain)
        }
        if model.canStop {
            Divider()
            Button("Stop", systemImage: "stop.fill", action: onStop)
        }
        if model.canRemove {
            Divider()
            Button("Remove from List", systemImage: "xmark", action: onRemove)
        }
    }
}

#Preview {
    VideoJobRow(model: .preview, onStop: {}, onRemove: {}, onCompressAgain: {}, onReveal: { _ in }, onOpen: { _ in })
        .previewEnvironment()
}
