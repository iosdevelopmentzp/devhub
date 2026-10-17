import SwiftUI

struct LocalBranchTags: View {
    @Environment(WorktreesStore.self) private var worktrees

    let branch: GitBranch
    let isCurrent: Bool

    private var checkout: WorktreeInfo? {
        branch.worktreePath == nil ? nil : worktrees.worktree(forBranch: branch.name)
    }

    var body: some View {
        FlowLayout(spacing: 6, lineSpacing: 4) {
            if isCurrent {
                Tag("current", tint: .blue)
            }
            if let path = branch.worktreePath, isCurrent == false {
                Tag(URL(fileURLWithPath: path).lastPathComponent, tint: .indigo, systemImage: "square.stack.3d.up")
                    .hint("Checked out in \(path)")
            }
            if let checkout, checkout.changeCount > 0, isCurrent == false {
                Tag(checkout.changeCount == 1 ? "1 change" : "\(checkout.changeCount) changes", tint: .orange)
            }
            if branch.ahead > 0 {
                Tag("\(branch.ahead)", tint: .blue, systemImage: "arrow.up")
            }
            if branch.behind > 0 {
                Tag("\(branch.behind)", tint: .purple, systemImage: "arrow.down")
            }
            if branch.isUpstreamGone {
                Tag("remote deleted", tint: .red)
            } else if branch.isLocalOnly {
                Tag("local only", tint: .orange)
            }
            if branch.countsAsMerged {
                Tag("merged", tint: .purple)
            }
        }
    }
}

#Preview {
    LocalBranchTags(branch: GitBranch(name: "feature/example", upstream: nil, ahead: 1, behind: 0, isUpstreamGone: false, commitDate: nil, worktreePath: nil, subject: "", lastVisit: nil, isMerged: false), isCurrent: true)
        .padding()
        .previewEnvironment()
}
