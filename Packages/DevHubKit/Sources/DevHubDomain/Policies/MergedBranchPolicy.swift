import Foundation

package enum MergedBranchPolicy {
    package static func isMerged(branch: String, upstream: String?, ahead: Int, mergedBranches: Set<String>, remote: String) -> Bool {
        mergedBranches.contains(branch) && upstream == "\(remote)/\(branch)" && ahead == 0
    }
}
