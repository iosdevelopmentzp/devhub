import Foundation
import DevHubDomain

enum MergeRequestFilterChipMapper {

    static func chips(for filter: MergeRequestFilter) -> [MergeRequestFilterChipModel] {
        var chips: [MergeRequestFilterChipModel] = []
        if let target = filter.targetBranch {
            chips.append(MergeRequestFilterChipModel(kind: .targetBranch, title: "into \(target)", systemImage: "arrow.triangle.branch"))
        }
        if let label = filter.label {
            chips.append(MergeRequestFilterChipModel(kind: .label, title: label, systemImage: "tag"))
        }
        if filter.onlyConflicts {
            chips.append(MergeRequestFilterChipModel(kind: .onlyConflicts, title: "with conflicts", systemImage: "exclamationmark.triangle"))
        }
        if filter.onlyReady {
            chips.append(MergeRequestFilterChipModel(kind: .onlyReady, title: "ready to merge", systemImage: "checkmark.circle"))
        }
        return chips
    }
}
