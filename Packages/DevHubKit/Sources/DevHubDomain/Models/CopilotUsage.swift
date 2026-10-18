import Foundation

package struct CopilotUsage: Hashable, Sendable {
    package var plan: String?
    package var limits: [UsageLimit]
    package var updatedAt: Date

    package init(plan: String?, limits: [UsageLimit], updatedAt: Date) {
        self.plan = plan
        self.limits = limits
        self.updatedAt = updatedAt
    }

    package var isUnlimited: Bool {
        limits.isEmpty
    }
}
