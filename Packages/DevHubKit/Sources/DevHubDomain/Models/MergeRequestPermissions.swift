import Foundation

package struct MergeRequestPermissions: Hashable, Sendable {
    package static let none = MergeRequestPermissions(canMerge: false, canApprove: false)

    package let canMerge: Bool
    package let canApprove: Bool

    package init(canMerge: Bool, canApprove: Bool) {
        self.canMerge = canMerge
        self.canApprove = canApprove
    }
}
