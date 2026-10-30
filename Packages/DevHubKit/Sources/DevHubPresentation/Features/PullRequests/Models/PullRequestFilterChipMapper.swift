import Foundation
import DevHubDomain

enum PullRequestFilterChipMapper {

    static func chips(for filter: PullRequestFilter) -> [PullRequestFilterChipModel] {
        var chips: [PullRequestFilterChipModel] = []
        if let target = filter.targetBranch {
            chips.append(PullRequestFilterChipModel(kind: .targetBranch, title: "into \(target)", systemImage: "arrow.triangle.branch"))
        }
        for label in filter.labels {
            chips.append(PullRequestFilterChipModel(kind: .label(label), title: label, systemImage: "tag"))
        }
        if let author = filter.author {
            chips.append(PullRequestFilterChipModel(kind: .author, title: "by \(author)", systemImage: "person.crop.circle"))
        }
        if let assignee = filter.assignee {
            chips.append(PullRequestFilterChipModel(kind: .assignee, title: "assigned to \(assignee)", systemImage: "person.badge.shield.checkmark"))
        }
        if let reviewer = filter.reviewer {
            chips.append(PullRequestFilterChipModel(kind: .reviewer, title: "review by \(reviewer)", systemImage: "eyeglasses"))
        }
        if filter.onlyConflicts {
            chips.append(PullRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle"))
        }
        if filter.onlyReady {
            chips.append(PullRequestFilterChipModel(kind: .onlyReady, title: "ready to merge", systemImage: "checkmark.circle"))
        }
        return chips
    }
}
