import SwiftUI

struct CommitRow: View {
    @Environment(GitStore.self) private var store

    let commit: GitCommit

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(commit.subject)
                    .font(.callout)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(commit.shortHash)
                        .font(.caption.monospaced())
                    Text("\(commit.author) · \(DisplayFormat.relative(commit.date))")
                        .lineLimit(1)
                    if commit.isPushed == false {
                        Tag("not pushed", tint: .orange)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(isHovered ? Theme.hover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { store.copyHash(commit) }
        .hint("\(commit.hash)\n\(commit.subject)")
    }
}

#Preview {
    CommitRow(commit: GitCommit(hash: "0123456789abcdef0123456789abcdef01234567", author: "Ada", date: Date(), subject: "Add the example", isPushed: false))
        .previewEnvironment()
}
