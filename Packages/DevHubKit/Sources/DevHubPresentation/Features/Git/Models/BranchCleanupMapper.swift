import Foundation
import DevHubDomain
import DevHubUI

enum BranchCleanupMapper {
    private static let shownNames = 5

    static func model(for candidates: [GitBranch]) -> BranchCleanupModel? {
        guard candidates.isEmpty == false else { return nil }
        let names = candidates.prefix(shownNames).map(\.name).joined(separator: ", ")
        let rest = candidates.count - shownNames
        return BranchCleanupModel(
            title: "Delete \(CountText.count(candidates.count, "merged branch", "merged branches"))?",
            names: rest > 0 ? "\(names) and \(rest) more" : names,
            showsForceToggle: candidates.contains(where: \.isGone)
        )
    }

    static func progressText(_ progress: BulkProgress) -> String {
        "Deleting \(progress.done + 1) of \(progress.total)…"
    }
}
