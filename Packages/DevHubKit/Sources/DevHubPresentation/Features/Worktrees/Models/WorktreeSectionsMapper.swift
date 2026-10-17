import Foundation
import DevHubDomain
import DevHubUI

enum WorktreeSectionsMapper {

    static func sections(
        for worktrees: [Worktree],
        rowModel: (Worktree) -> WorktreeRowModel
    ) -> [WorktreeSectionModel] {
        let isMoreRecent: (Worktree, Worktree) -> Bool = { ($0.lastActivity ?? .distantPast) > ($1.lastActivity ?? .distantPast) }
        let others = worktrees.filter { $0.isMain == false }
        let groups: [(title: String, items: [Worktree])] = [
            ("Main checkout", worktrees.filter(\.isMain)),
            ("In progress", others.filter { $0.isMissing == false && $0.isFinished == false }.sorted(by: isMoreRecent)),
            ("Finished · merged or remote branch deleted", others.filter { $0.isMissing == false && $0.isFinished }.sorted(by: isMoreRecent)),
            ("Missing folder", others.filter(\.isMissing))
        ]
        return groups
            .filter { $0.items.isEmpty == false }
            .map { WorktreeSectionModel(title: $0.title, rows: $0.items.map(rowModel)) }
    }
}
