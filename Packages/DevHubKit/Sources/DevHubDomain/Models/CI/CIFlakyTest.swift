import Foundation

package struct CIFlakyTest: Hashable, Sendable {
    package let className: String
    package let name: String
    package let jobName: String?
    package let workflowName: String?
    package let timesFlaked: Int
    package let source: CIFlakySource

    package init(className: String, name: String, jobName: String?, workflowName: String?, timesFlaked: Int, source: CIFlakySource = .insights) {
        self.className = className
        self.name = name
        self.jobName = jobName
        self.workflowName = workflowName
        self.timesFlaked = timesFlaked
        self.source = source
    }
}
