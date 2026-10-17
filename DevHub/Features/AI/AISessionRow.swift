import SwiftUI

struct AISessionRow: View {
    @Environment(AIStore.self) private var store

    let session: AISession

    @State private var isHovered = false

    private var tint: Tint { session.provider == .claude ? .orange : .blue }

    private var symbol: String { session.provider == .claude ? "asterisk" : "sparkle" }

    var body: some View {
        HStack(spacing: 10) {
            IconTile(systemImage: symbol, tint: tint)
                .hint(session.provider.title)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .hintWhenTruncated(session.title)
                HStack(spacing: 6) {
                    Text(session.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                    Text(session.folder)
                        .font(.caption.monospaced())
                        .foregroundStyle(session.folderExists ? Color.secondary : Tint.red.color)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(session.cwd, label: "folder")
                    if let branch = session.branch {
                        Tag(branch, tint: .blue)
                    }
                }
                if session.lastPrompt.isEmpty == false {
                    Text(session.lastPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .hintWhenTruncated(session.lastPrompt)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                store.resume(session)
            } label: {
                Label("Resume", systemImage: "terminal")
            }
            .controlSize(.small)
            .fixedSize()
            .disabled(session.folderExists == false)
            .hint(session.folderExists ? session.fullResumeCommand : "The folder no longer exists: \(session.folder)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.hover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Resume", systemImage: "terminal") { store.resume(session) }
                .disabled(session.folderExists == false)
            Button("Copy resume command", systemImage: "doc.on.doc") { store.copyResumeCommand(session) }
        }
    }
}

#Preview {
    AISessionRow(session: AISession(id: "1", provider: .claude, title: "Example", date: Date(), folder: "~/Projects/app", branch: "main", lastPrompt: "Hello"))
        .previewEnvironment()
}
