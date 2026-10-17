import Foundation
import DevHubDomain
import DevHubUI

struct CommitBoxModel: Equatable {
    var summary: String
    var canCommit: Bool
    var canCommitAndPush: Bool

    static let preview = CommitBoxModel(
        summary: "2 staged files on feature/ABC-2324-paid-call",
        canCommit: true,
        canCommitAndPush: true
    )
}
