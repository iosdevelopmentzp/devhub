import Foundation

package struct CIWorkflow: Hashable, Sendable, Codable {
    package let id: String
    package let name: String
    package let status: CheckStatus
    package let runID: String?
    package let jobs: [CIJob]

    package init(id: String, name: String, status: CheckStatus, runID: String?, jobs: [CIJob]) {
        self.id = id
        self.name = name
        self.status = status
        self.runID = runID
        self.jobs = jobs
    }
}
