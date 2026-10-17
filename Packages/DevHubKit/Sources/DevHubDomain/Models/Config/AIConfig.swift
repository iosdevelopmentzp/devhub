import Foundation

package struct AIConfig: Codable, Hashable, Sendable {
    package var reviewCommand: String? = nil

    package init(reviewCommand: String? = nil) {
        self.reviewCommand = reviewCommand
    }
}
