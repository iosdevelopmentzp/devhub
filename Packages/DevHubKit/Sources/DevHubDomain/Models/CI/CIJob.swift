import Foundation

package struct CIJob: Hashable, Sendable {
    package let id: String
    package let name: String
    package let status: CheckStatus
    package let isApproval: Bool

    package init(id: String, name: String, status: CheckStatus, isApproval: Bool) {
        self.id = id
        self.name = name
        self.status = status
        self.isApproval = isApproval
    }
}
