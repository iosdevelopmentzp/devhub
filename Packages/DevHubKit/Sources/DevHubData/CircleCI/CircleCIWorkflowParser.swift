import Foundation
import DevHubDomain

enum CircleCIWorkflowParser {
    private struct Workflow: Decodable {
        struct Job: Decodable {
            let id: String?
            let name: String?
            let phase: String?
            let outcome: String?
            let status: String?
            let type: String?
        }

        let id: String?
        let name: String?
        let phase: String?
        let outcome: String?
        let runId: String?
        let jobs: [Job]?
    }

    static func workflow(from data: Data, id fallbackID: String) throws -> CIWorkflow {
        let dto = try CircleCIJSON.decode(Workflow.self, from: data)
        return CIWorkflow(
            id: dto.id ?? fallbackID,
            name: dto.name ?? "",
            status: CircleCIStatusMapper.status(phase: dto.phase, outcome: dto.outcome),
            runID: dto.runId,
            jobs: (dto.jobs ?? []).map(job)
        )
    }

    private static func job(_ dto: Workflow.Job) -> CIJob {
        CIJob(
            id: dto.id ?? "",
            name: dto.name ?? "",
            status: CircleCIStatusMapper.status(phase: dto.phase ?? dto.status, outcome: dto.outcome),
            isApproval: dto.type == "approval"
        )
    }
}
