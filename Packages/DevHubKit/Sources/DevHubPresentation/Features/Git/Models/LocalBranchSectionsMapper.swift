import Foundation
import DevHubDomain
import DevHubUI

enum LocalBranchSectionsMapper {

    static func sections(
        for branches: [GitBranch],
        currentBranch: String?,
        pinnedNames: Set<String>,
        rowModel: (GitBranch) -> LocalBranchRowModel
    ) -> [LocalBranchSectionModel] {
        let pinned = branches.filter { pinnedNames.contains($0.name) }
        let unpinned = branches.filter { pinnedNames.contains($0.name) == false }
        let isCheckedOut: (GitBranch) -> Bool = { $0.name == currentBranch || $0.worktreePath != nil }
        let others = unpinned.filter { isCheckedOut($0) == false }
        let groups: [(kind: LocalBranchSectionModel.Kind, title: String, items: [GitBranch])] = [
            (.pinned, "Pinned", pinned),
            (.checkedOut, "Checked out", unpinned.filter { $0.name == currentBranch } + unpinned.filter { $0.name != currentBranch && isCheckedOut($0) }),
            (.active, "Active", others.filter { BranchCleanupPolicy.isFinished($0) == false }),
            (.merged, "Merged · safe to delete", others.filter(BranchCleanupPolicy.isFinished)),
        ]
        return groups
            .filter { $0.items.isEmpty == false }
            .map { LocalBranchSectionModel(id: $0.kind, title: $0.title, detail: "\($0.items.count)", rows: $0.items.map(rowModel)) }
    }
}
