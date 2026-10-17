import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptRow: View {
    let model: ScriptRowModel
    let run: () -> Void

    var body: some View {
        RowContainer { isHovered in
            row(isHovered: isHovered)
        }
    }

    private func row(isHovered: Bool) -> some View {
        HStack(spacing: 10) {
            IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.callout.weight(.semibold))
                Text(model.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(model.fileName)
                        .font(.caption2.monospaced())
                    Text("·")
                    Text(model.lastRunText)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Group {
                if model.isRunning {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Run", systemImage: "play.fill") {
                        run()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .controlSize(.small)
            .frame(width: 64)

            OverflowMenu {
                Button(model.editTitle, systemImage: "pencil") {}
                Button("Reveal in Finder", systemImage: "folder") {}
                Button("Copy Command", systemImage: "doc.on.doc") {}
                Divider()
                Button("Remove", systemImage: "trash", role: .destructive) {}
            }
            .opacity(isHovered ? 1 : 0)
        }
    }
}

#Preview {
    ScriptRow(model: .preview) {}
        .previewEnvironment()
}
