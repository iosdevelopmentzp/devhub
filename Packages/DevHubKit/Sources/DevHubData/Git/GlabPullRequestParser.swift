import Foundation
import DevHubDomain

enum GlabPullRequestParser {
    private struct PullRequestDTO: Decodable {
        struct Author: Decodable {
            let username: String
        }

        let iid: Int
        let title: String
        let state: String
        let draft: Bool?
        let webUrl: String?
        let author: Author?
        let hasConflicts: Bool?
        let detailedMergeStatus: String?
        let targetBranch: String
    }

    private struct PipelineDTO: Decodable {
        let status: String
        let webUrl: String?
        let updatedAt: Date?
    }

    static func mergeRequest(from data: Data) throws -> PullRequestInfo? {
        let requests: [PullRequestDTO] = try decode(data)
        let open = requests.first { $0.state == "opened" } ?? requests.first
        return open.map { dto in
            PullRequestInfo(
                iid: dto.iid,
                title: dto.title,
                state: state(dto.state),
                isDraft: dto.draft ?? false,
                webURL: dto.webUrl.flatMap(URL.init(string:)),
                author: dto.author?.username ?? "",
                hasConflicts: dto.hasConflicts ?? false,
                detailedStatus: dto.detailedMergeStatus.map(detail),
                targetBranch: dto.targetBranch
            )
        }
    }

    static func pipeline(from data: Data) throws -> PipelineInfo? {
        let pipelines: [PipelineDTO] = try decode(data)
        return pipelines.first.map { dto in
            PipelineInfo(status: pipelineStatus(dto.status), webURL: dto.webUrl.flatMap(URL.init(string:)), updatedAt: dto.updatedAt)
        }
    }

    static func decode<Value: Decodable>(_ data: Data) throws -> Value {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            return ISO8601.date(from: text) ?? .distantPast
        }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw PullRequestError.command("Unexpected answer from GitLab: \(error.localizedDescription)")
        }
    }

    static func state(_ name: String) -> PullRequestState {
        switch name {
        case "opened": .opened
        case "merged": .merged
        case "closed": .closed
        case "locked": .locked
        default: .other(name)
        }
    }

    static func detail(_ name: String) -> MergeDetail {
        switch name {
        case "mergeable": .mergeable
        case "not_approved": .notApproved
        case "ci_must_pass": .ciMustPass
        case "ci_still_running": .ciStillRunning
        case "discussions_not_resolved": .discussionsNotResolved
        case "need_rebase": .needRebase
        case "draft_status": .draftStatus
        default: .other(name)
        }
    }

    static func pipelineStatus(_ name: String) -> PipelineStatus {
        switch name {
        case "success": .success
        case "failed": .failed
        case "running": .running
        case "pending": .pending
        case "created": .created
        case "waiting_for_resource": .waitingForResource
        case "preparing": .preparing
        case "scheduled": .scheduled
        case "canceled": .canceled
        case "skipped": .skipped
        case "manual": .manual
        default: .other(name)
        }
    }
}
