import Foundation

package struct FlakyTestRecord: Codable, Hashable, Sendable {
    package let className: String
    package let name: String
    package let jobName: String?
    package let workflowName: String?
    package let timesFlaked: Int
    package let lastFlakedAt: Date

    package init(className: String, name: String, jobName: String?, workflowName: String?, timesFlaked: Int, lastFlakedAt: Date) {
        self.className = className
        self.name = name
        self.jobName = jobName
        self.workflowName = workflowName
        self.timesFlaked = timesFlaked
        self.lastFlakedAt = lastFlakedAt
    }
}
