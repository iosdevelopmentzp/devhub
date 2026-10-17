import SwiftUI

struct GitTags: View {
    @Environment(GitStore.self) private var store

    private var status: GitStatus { store.status }

    var body: some View {
        if status.isClean {
            Tag("clean", tint: .green, systemImage: "checkmark")
        } else {
            Tag(status.changeCount == 1 ? "1 change" : "\(status.changeCount) changes", tint: .orange)
        }
        upstream
        if let distance = store.details.distance {
            Tag(distanceText(distance), tint: distance.behind > 0 ? .purple : .blue)
                .hint("Commits compared with \(store.baseBranch)")
        }
        if store.details.stashCount > 0 {
            Tag("\(store.details.stashCount) stashed", tint: .gray)
        }
    }

    @ViewBuilder
    private var upstream: some View {
        if status.branch == nil {
            EmptyView()
        } else if let name = status.upstream {
            if status.ahead > 0 {
                Tag("\(status.ahead) to push", tint: .orange, systemImage: "arrow.up")
                    .hint("Commits not on \(name)")
            }
            if status.behind > 0 {
                Tag("\(status.behind) to pull", tint: .purple, systemImage: "arrow.down")
                    .hint("Commits on \(name) that are not here")
            }
            if status.ahead == 0, status.behind == 0 {
                Tag(name, tint: .green, systemImage: "arrow.up.arrow.down")
                    .hint("Up to date with \(name)")
            }
        } else {
            Tag("no upstream", tint: .orange)
        }
    }

    private func distanceText(_ distance: BranchDistance) -> String {
        if distance.ahead == 0, distance.behind == 0 {
            return "level with \(store.baseBranch)"
        }
        return "\(distance.ahead) ahead / \(distance.behind) behind \(store.baseBranch)"
    }
}

#Preview {
    FlowLayout(spacing: 6, lineSpacing: 4) {
        GitTags()
    }
    .padding()
    .previewEnvironment()
}
