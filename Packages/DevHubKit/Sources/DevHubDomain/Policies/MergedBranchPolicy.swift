import Foundation

package enum MergedBranchPolicy {
    package static func isMerged(branch: String, upstream: String?, ahead: Int, mergedBranches: Set<String>) -> Bool {
        mergedBranches.contains(branch) && upstream == "origin/\(branch)" && ahead == 0
    }
}
