import SwiftUI

struct WorktreeSectionView: View {
    let title: String
    let worktrees: [WorktreeInfo]

    var body: some View {
        if worktrees.isEmpty == false {
            VStack(spacing: 0) {
                SectionHeader("\(title) · \(worktrees.count)")
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                ForEach(worktrees) { worktree in
                    WorktreeRow(worktree: worktree)
                    if worktree.id != worktrees.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
        }
    }
}

#Preview {
    WorktreeSectionView(title: "In progress", worktrees: [WorktreeInfo.sample(path: "/tmp/example-feature", branch: "feature/example")])
        .previewEnvironment()
}
