import Foundation
import DevHubDomain

enum PullRequestFilterChipMapper {

    static func chips(for filter: PullRequestFilter) -> [PullRequestFilterChipModel] {
        var chips: [PullRequestFilterChipModel] = []
        if let target = filter.targetBranch {
            chips.append(PullRequestFilterChipModel(kind: .targetBranch, title: "into \(target)", systemImage: "arrow.triangle.branch"))
        }
        if let label = filter.label {
            chips.append(PullRequestFilterChipModel(kind: .label, title: label, systemImage: "tag"))
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
