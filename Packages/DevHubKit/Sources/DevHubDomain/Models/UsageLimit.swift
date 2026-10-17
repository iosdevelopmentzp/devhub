import Foundation

package struct UsageLimit: Identifiable, Hashable, Sendable {
    package let id: String
    package var title: String
    package var usedFraction: Double
    package var resetsAt: Date?

    package init(id: String, title: String, usedFraction: Double, resetsAt: Date?) {
        self.id = id
        self.title = title
        self.usedFraction = usedFraction
        self.resetsAt = resetsAt
    }

    package var percentText: String {
        "\(Int((usedFraction * 100).rounded()))%"
    }
}
