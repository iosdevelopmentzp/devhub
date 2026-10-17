import Foundation

package struct MergeRequestFilter: Hashable, Codable, Sendable {
    package var targetBranch: String? = nil
    package var label: String? = nil
    package var onlyConflicts = false
    package var onlyReady = false

    package init(targetBranch: String? = nil, label: String? = nil, onlyConflicts: Bool = false, onlyReady: Bool = false) {
        self.targetBranch = targetBranch
        self.label = label
        self.onlyConflicts = onlyConflicts
        self.onlyReady = onlyReady
    }

    package var isActive: Bool {
        self != MergeRequestFilter()
    }
}
