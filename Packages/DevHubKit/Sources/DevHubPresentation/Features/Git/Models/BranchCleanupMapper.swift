import Foundation
import DevHubDomain
import DevHubUI

enum BranchCleanupMapper {
    private static let shownNames = 5

    static func model(for candidates: [GitBranch], kept: [String]) -> BranchCleanupModel? {
        guard candidates.isEmpty == false else { return nil }
        let names = candidates.prefix(shownNames).map(\.name).joined(separator: ", ")
        let rest = candidates.count - shownNames
        return BranchCleanupModel(
            title: "Delete \(CountText.count(candidates.count, "merged branch", "merged branches"))?",
            names: rest > 0 ? "\(names) and \(rest) more" : names,
            showsForceToggle: candidates.contains(where: \.isGone),
            hint: hint(kept: kept)
        )
    }

    static func hint(kept: [String]) -> String {
        var unique: [String] = []
        for name in kept where name.isEmpty == false && unique.contains(name) == false {
            unique.append(name)
        }
        let base = "Delete every merged branch in this list that is not checked out."
        guard unique.isEmpty == false else { return base }
        let list = unique.count == 1 ? unique[0] : unique.dropLast().joined(separator: ", ") + " and " + unique[unique.count - 1]
        return "\(base) \(list) \(unique.count == 1 ? "stays" : "stay")."
    }

    static func progressText(_ progress: BulkProgress) -> String {
        "Deleting \(progress.done + 1) of \(progress.total)…"
    }
}
