import Foundation

package struct CIWorkflowDetails: Hashable, Sendable, Codable {
    package let id: String
    package let pipelineNumber: Int?
    package let projectSlug: String?
    package let createdAt: Date?
    package let stoppedAt: Date?
    package let jobs: [CIJobDetails]

    package init(id: String, pipelineNumber: Int?, projectSlug: String?, createdAt: Date?, stoppedAt: Date?, jobs: [CIJobDetails]) {
        self.id = id
        self.pipelineNumber = pipelineNumber
        self.projectSlug = projectSlug
        self.createdAt = createdAt
        self.stoppedAt = stoppedAt
        self.jobs = jobs
    }

    package func job(_ id: String) -> CIJobDetails? {
        jobs.first { $0.id == id }
    }
}
