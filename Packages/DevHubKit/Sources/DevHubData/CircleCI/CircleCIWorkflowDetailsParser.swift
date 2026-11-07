import Foundation
import DevHubDomain

enum CircleCIWorkflowDetailsParser {
    private struct Workflow: Decodable {
        let id: String?
        let pipelineNumber: Int?
        let projectSlug: String?
        let createdAt: String?
        let stoppedAt: String?
    }

    private struct Job: Decodable {
        let id: String?
        let jobNumber: Int?
        let startedAt: String?
        let stoppedAt: String?
        let approvalRequestId: String?
    }

    private struct JobPage: Decodable {
        let items: [Job]?
    }

    static func details(workflow workflowData: Data, jobs jobsData: Data, id fallbackID: String) throws -> CIWorkflowDetails {
        let workflow = try CircleCIJSON.decode(Workflow.self, from: workflowData)
        let jobs: [Job]
        if let list = try? CircleCIJSON.decode([Job].self, from: jobsData) {
            jobs = list
        } else {
            jobs = try CircleCIJSON.decode(JobPage.self, from: jobsData).items ?? []
        }
        return CIWorkflowDetails(
            id: workflow.id ?? fallbackID,
            pipelineNumber: workflow.pipelineNumber,
            projectSlug: workflow.projectSlug,
            createdAt: workflow.createdAt.flatMap(ISO8601.date(from:)),
            stoppedAt: workflow.stoppedAt.flatMap(ISO8601.date(from:)),
            jobs: jobs.compactMap(job)
        )
    }

    private static func job(_ dto: Job) -> CIJobDetails? {
        guard let id = dto.id, id.isEmpty == false else { return nil }
        return CIJobDetails(
            id: id,
            number: dto.jobNumber,
            startedAt: dto.startedAt.flatMap(ISO8601.date(from:)),
            stoppedAt: dto.stoppedAt.flatMap(ISO8601.date(from:)),
            approvalRequestID: dto.approvalRequestId
        )
    }
}
