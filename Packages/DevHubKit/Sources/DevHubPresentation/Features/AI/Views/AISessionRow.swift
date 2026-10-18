import SwiftUI
import DevHubDomain
import DevHubUI

struct AISessionRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: AISessionRowModel

    var body: some View {
        RowContainer { isHovered in
            row(isHovered: isHovered)
        }
    }

    private func row(isHovered: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(2)
                    .hintWhenTruncated(model.title)
                HStack(spacing: 6) {
                    Text(model.dateText)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(model.folderDisplayPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(model.folderPath, label: model.folderDisplayPath)
                }
                tags
                if let prompt = model.lastPrompt {
                    Text(prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .hintWhenTruncated(prompt)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 2) {
                OverflowMenu {
                    Button("Copy resume command", systemImage: "doc.on.doc") {
                        toaster.copy(model.resumeCommand, label: "Resume command")
                    }
                    Button("Copy session ID", systemImage: "number") {
                        toaster.copy(model.id, label: model.id)
                    }
                    Button("Show folder in Finder", systemImage: "folder") {
                        appActions.openInFinder(path: model.folderPath)
                    }
                    .disabled(model.canShowFolder == false)
                }
                .opacity(isHovered ? 1 : 0)
                Button("Resume", systemImage: "terminal") {
                    appActions.runInTerminal(model.terminalCommand, at: model.folderPath, title: "Resumed Claude session")
                }
                .controlSize(.small)
                .fixedSize()
                .disabled(model.canResume == false)
                .hint(model.resumeHint)
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        if model.hasTags {
            FlowLayout(spacing: 6) {
                if let tag = model.branchTag {
                    ModelTag(model: tag)
                        .copyOnClick(tag.text, label: tag.text)
                }
                ForEach(model.statusTags, id: \.self) { tag in
                    ModelTag(model: tag)
                }
            }
        }
    }
}

#Preview {
    AISessionRow(model: .preview)
        .previewEnvironment()
}
