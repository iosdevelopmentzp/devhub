import SwiftUI

struct WorktreeTags: View {
    @Environment(WorktreesStore.self) private var store

    let worktree: WorktreeInfo

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 4) {
            if worktree.isMain {
                Tag("main checkout", tint: .indigo)
            }
            if worktree.isMissing {
                Tag("folder missing", tint: .red)
            }
            if worktree.isLocked {
                Tag("locked", tint: .gray, systemImage: "lock")
            }
            if worktree.isMerged, worktree.isMain == false {
                Tag("merged", tint: .purple)
            }
            if worktree.isRemoteGone {
                Tag("remote deleted", tint: .purple)
            }
            if worktree.isNotPushed, worktree.isMissing == false {
                Tag("not pushed", tint: .orange)
            }
            if worktree.changeCount > 0 {
                Tag(worktree.changeCount == 1 ? "1 change" : "\(worktree.changeCount) changes", tint: .orange)
            }
            if worktree.ahead > 0 {
                Tag("\(worktree.ahead)", tint: .blue, systemImage: "arrow.up")
            }
            if worktree.behind > 0 {
                Tag("\(worktree.behind)", tint: .purple, systemImage: "arrow.down")
            }
            if let size = store.derivedSize(of: worktree) {
                Tag(DisplayFormat.bytes(size), tint: .gray, systemImage: "internaldrive")
                    .hint("DerivedData of this worktree")
            }
            if worktree.needsBootstrap {
                Tag("needs bootstrap", tint: .orange)
            }
        }
    }
}

#Preview {
    WorktreeTags(worktree: WorktreeInfo.sample(path: "/tmp/example", branch: "feature/example"))
        .padding()
        .previewEnvironment()
}
