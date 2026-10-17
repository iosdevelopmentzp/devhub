import Foundation
import DevHubDomain
import DevHubUI

enum ReflogRowMapper {

    static func model(for entry: GitReflogEntry, expansion: CommitRowMapper.Expansion?) -> ReflogRowModel {
        ReflogRowModel(
            id: entry.id,
            selector: entry.selector,
            hash: entry.hash,
            shortHash: entry.shortHash,
            actionTag: TagModel(entry.action, tint: tint(for: entry.action), hint: hint(for: entry.action)),
            message: entry.message,
            dateText: entry.date?.relativeDescription,
            files: expansion.map { CommitRowMapper.files(for: entry.hash, $0) }
        )
    }

    private static func tint(for action: String) -> Tint {
        switch verb(action) {
        case "commit": action.contains("amend") ? .orange : .green
        case "checkout", "switch": .blue
        case "rebase": .orange
        case "reset": .red
        case "merge", "pull", "cherry-pick": .purple
        default: .secondary
        }
    }

    private static func hint(for action: String) -> String? {
        switch verb(action) {
        case "reset": "HEAD moved with git reset. The commits it left are still here and can be restored."
        case "rebase": "A step of a rebase"
        case "commit": action.contains("amend") ? "The last commit was replaced by this one" : nil
        default: nil
        }
    }

    private static func verb(_ action: String) -> String {
        String(action.prefix { $0 != " " })
    }
}
