import Foundation

package struct ReviewSnapshot: Hashable, Sendable, Codable {
    package var reviewedAt: Date?
    package var files: [String: String]
    package var viewed: [String: String]
    package var updatedAt: Date

    package init(reviewedAt: Date?, files: [String: String], viewed: [String: String], updatedAt: Date) {
        self.reviewedAt = reviewedAt
        self.files = files
        self.viewed = viewed
        self.updatedAt = updatedAt
    }
}
