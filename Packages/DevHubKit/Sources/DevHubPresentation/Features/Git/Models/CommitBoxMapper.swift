import Foundation
import DevHubDomain
import DevHubUI

enum CommitBoxMapper {

    static func model(
        staged: [GitFileChange],
        conflictedCount: Int,
        isAmend: Bool,
        canCommit: Bool,
        isGitBusy: Bool,
        branch: String?
    ) -> CommitBoxModel {
        CommitBoxModel(
            summary: summary(staged: staged, conflictedCount: conflictedCount, isAmend: isAmend, branch: branch),
            canCommit: canCommit,
            canCommitAndPush: canCommit && isGitBusy == false
        )
    }

    private static func summary(staged: [GitFileChange], conflictedCount: Int, isAmend: Bool, branch: String?) -> String {
        if conflictedCount > 0 {
            return "Resolve \(CountText.invariant(conflictedCount, "conflicts")) first"
        }
        if staged.isEmpty, isAmend == false {
            return "Stage files to commit"
        }
        let count = Set(staged.map(\.path)).count
        return "\(CountText.count(count, "staged file")) on \(branch ?? "HEAD")"
    }
}
