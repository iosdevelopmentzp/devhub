import SwiftUI
import DevHubDomain
import DevHubUI

struct CommitRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let model: CommitRowModel
    let onToggle: () -> Void
    let onToggleFile: (_ path: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowContainer(verticalPadding: 6) { _ in
                summary
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onToggle)
            }
            .contextMenu { menu }
            if let containingTags = model.containingTags {
                containing(containingTags)
            }
            if let files = model.files {
                CommitFilesList(files: files, onToggleFile: onToggleFile)
                    .padding(.leading, 18)
                    .padding(.bottom, 6)
            }
        }
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 10)
            Text(model.shortHash)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .copyOnClick(model.hash, label: model.shortHash)
            ForEach(model.refTags, id: \.self) { tag in
                ModelTag(model: tag)
                    .fixedSize()
            }
            Text(model.subject)
                .font(.callout)
                .lineLimit(1)
                .hintWhenTruncated(model.subject)
            ForEach(model.tags, id: \.self) { tag in
                ModelTag(model: tag)
            }
            Spacer(minLength: 6)
            Text(model.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let dateText = model.dateText {
                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func containing(_ tags: [TagModel]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(tags.isEmpty ? "In no branch" : "In")
                .font(.caption2)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    ModelTag(model: tag)
                }
            }
        }
        .padding(.leading, 32)
        .padding(.trailing, 14)
        .padding(.bottom, 6)
        .hint("The branches that contain this commit (git branch -a --contains)")
    }

    @ViewBuilder
    private var menu: some View {
        Button(model.isExpanded ? "Hide Files" : "Show Files", systemImage: "doc.text", action: onToggle)
        Divider()
        Button("Copy Hash", systemImage: "number") { toaster.copy(model.hash, label: model.shortHash) }
        Button("Copy Subject", systemImage: "doc.on.doc") { toaster.copy(model.subject, label: "Subject") }
        Button(words.openTitle, systemImage: "globe") { appActions.open(model.webURL) }
            .disabled(model.webURL == nil)
    }
}

#Preview {
    CommitRow(model: .preview, onToggle: {}, onToggleFile: { _ in })
        .previewEnvironment()
}
