import Foundation
import DevHubDomain

enum CircleCIRunParser {
    private struct Run: Decodable {
        let id: String?
        let phase: String?
        let outcome: String?
        let branch: String?
        let revision: String?
        let createdAt: String?
    }

    private struct Page: Decodable {
        let items: [Run]?
        let runs: [Run]?
    }

    static func runs(from data: Data) throws -> [CIRun] {
        let dtos: [Run]
        if let list = try? CircleCIJSON.decode([Run].self, from: data) {
            dtos = list
        } else {
            let page = try CircleCIJSON.decode(Page.self, from: data)
            dtos = page.items ?? page.runs ?? []
        }
        return dtos.compactMap(run)
    }

    private static func run(_ dto: Run) -> CIRun? {
        guard let id = dto.id, id.isEmpty == false else { return nil }
        return CIRun(
            id: id,
            status: CircleCIStatusMapper.status(phase: dto.phase, outcome: dto.outcome),
            branch: dto.branch,
            revision: dto.revision,
            createdAt: dto.createdAt.flatMap(ISO8601.date(from:))
        )
    }
}
