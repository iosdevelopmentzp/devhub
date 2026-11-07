import Foundation

package struct CIJobDetails: Hashable, Sendable, Codable {
    package let id: String
    package let number: Int?
    package let startedAt: Date?
    package let stoppedAt: Date?
    package let approvalRequestID: String?

    package init(id: String, number: Int?, startedAt: Date?, stoppedAt: Date?, approvalRequestID: String?) {
        self.id = id
        self.number = number
        self.startedAt = startedAt
        self.stoppedAt = stoppedAt
        self.approvalRequestID = approvalRequestID
    }

    package func duration(now: Date) -> TimeInterval? {
        guard let startedAt else { return nil }
        return max(0, (stoppedAt ?? now).timeIntervalSince(startedAt))
    }
}
