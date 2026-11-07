import Foundation
import DevHubDomain

enum CircleCIWorkflowListParser {
    private struct Workflow: Decodable {
        let id: String?
        let name: String?
        let phase: String?
        let outcome: String?
        let currentOutcome: String?
        let runId: String?
    }

    private struct Page: Decodable {
        let items: [Workflow]?
        let workflows: [Workflow]?
    }

    static func workflows(from data: Data, runID: String) throws -> [CIWorkflow] {
        let dtos: [Workflow]
        if let list = try? CircleCIJSON.decode([Workflow].self, from: data) {
            dtos = list
        } else {
            let page = try CircleCIJSON.decode(Page.self, from: data)
            dtos = page.items ?? page.workflows ?? []
        }
        return dtos.compactMap { dto in
            guard let id = dto.id, id.isEmpty == false else { return nil }
            return CIWorkflow(
                id: id,
                name: dto.name ?? "",
                status: CircleCIStatusMapper.status(phase: dto.phase, outcome: dto.outcome, currentOutcome: dto.currentOutcome),
                runID: dto.runId ?? runID,
                jobs: []
            )
        }
    }
}
