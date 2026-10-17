import Foundation
import DevHubDomain

enum GlabGraphQLParser {
    private struct Response<Payload: Decodable>: Decodable {
        struct Failure: Decodable {
            let message: String
        }

        let data: Payload?
        let errors: [Failure]?
    }

    private struct Nodes<Node: Decodable>: Decodable {
        let nodes: [Node]
    }

    private struct User: Decodable {
        let username: String
    }

    private struct Label: Decodable {
        let title: String
    }

    private struct Pipeline: Decodable {
        struct Status: Decodable {
            let detailsPath: String?
        }

        let status: String
        let updatedAt: Date?
        let duration: Int?
        let finishedAt: Date?
        let failedJobsCount: Int?
        let detailedStatus: Status?
    }

    private struct DiffStatsSummary: Decodable {
        let additions: Int
        let deletions: Int
        let fileCount: Int
    }

    private struct Permissions: Decodable {
        let canMerge: Bool
        let canApprove: Bool
    }

    private struct MergeRequestNode: Decodable {
        let iid: String
        let title: String
        let state: String
        let draft: Bool?
        let webUrl: String?
        let author: User?
        let sourceBranch: String
        let targetBranch: String
        let conflicts: Bool?
        let detailedMergeStatus: String?
        let userNotesCount: Int?
        let updatedAt: Date?
        let headPipeline: Pipeline?
        let approvedBy: Nodes<User>?
        let labels: Nodes<Label>?
        let createdAt: Date?
        let mergedAt: Date?
        let closedAt: Date?
        let mergeUser: User?
        let commitCount: Int?
        let diffStatsSummary: DiffStatsSummary?
        let resolvableDiscussionsCount: Int?
        let resolvedDiscussionsCount: Int?
        let divergedFromTargetBranch: Bool?
        let squashOnMerge: Bool?
        let shouldRemoveSourceBranch: Bool?
        let diffHeadSha: String?
        let autoMergeEnabled: Bool?
        let userPermissions: Permissions?
    }

    private struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    private struct Connection: Decodable {
        let count: Int
        let pageInfo: PageInfo?
        let nodes: [MergeRequestNode]
    }

    private struct ListData: Decodable {
        struct CurrentUser: Decodable {
            let username: String
            let authoredMergeRequests: Connection?
            let assignedMergeRequests: Connection?
        }

        struct Project: Decodable {
            let mergeRequests: Connection?
        }

        let currentUser: CurrentUser?
        let project: Project?
    }

    private struct DetailsData: Decodable {
        struct Project: Decodable {
            let mergeRequest: MergeRequest?
        }

        struct MergeRequest: Decodable {
            let description: String?
            let headPipeline: HeadPipeline?
            let discussions: Nodes<Discussion>
        }

        struct HeadPipeline: Decodable {
            let duration: Int?
            let jobs: Nodes<Job>?
        }

        struct Job: Decodable {
            struct Stage: Decodable {
                let name: String?
            }

            let name: String?
            let webPath: String?
            let stage: Stage?
        }

        struct Discussion: Decodable {
            let id: String
            let resolvable: Bool
            let resolved: Bool
            let notes: Nodes<Note>
        }

        struct Note: Decodable {
            struct Position: Decodable {
                let filePath: String?
                let newLine: Int?
                let oldLine: Int?
            }

            let id: String?
            let body: String
            let system: Bool
            let author: User?
            let position: Position?
        }

        let project: Project?
    }

    static func list(from data: Data, host: String) throws -> MergeRequestList {
        let payload: ListData = try payload(data)
        guard let user = payload.currentUser else { throw MergeRequestError.notLoggedIn(tool: "glab", host: host) }
        let connection = user.authoredMergeRequests ?? user.assignedMergeRequests ?? payload.project?.mergeRequests
        guard let connection else { throw MergeRequestError.command("GitLab did not find the project") }
        return MergeRequestList(
            username: user.username,
            requests: connection.nodes.compactMap { summary($0, host: host) },
            totalCount: connection.count,
            endCursor: connection.pageInfo?.endCursor,
            hasNextPage: connection.pageInfo?.hasNextPage ?? false
        )
    }

    private struct LabelsData: Decodable {
        struct Project: Decodable {
            let labels: Nodes<Label>?
        }

        let project: Project?
    }

    static func labels(from data: Data) throws -> [String] {
        let payload: LabelsData = try payload(data)
        guard let project = payload.project else { throw MergeRequestError.command("GitLab did not find the project") }
        return (project.labels?.nodes ?? []).map(\.title).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private struct MutationPayload: Decodable {
        let errors: [String]?
    }

    static func mutation(from data: Data) throws {
        let payload: [String: MutationPayload] = try self.payload(data)
        let errors = payload.values.flatMap { $0.errors ?? [] }
        guard errors.isEmpty else { throw MergeRequestError.command(errors.joined(separator: " ")) }
    }

    static func details(from data: Data, host: String) throws -> MergeRequestDetails {
        let payload: DetailsData = try payload(data)
        guard let request = payload.project?.mergeRequest else { throw MergeRequestError.command("GitLab did not find the merge request") }
        let threads = request.discussions.nodes
            .filter { $0.resolvable && $0.resolved == false }
            .compactMap { discussion -> MergeRequestThread? in
                let notes = discussion.notes.nodes.filter { $0.system == false }
                guard let first = notes.first else { return nil }
                return MergeRequestThread(
                    id: discussion.id,
                    noteID: first.id.flatMap(noteID),
                    author: first.author?.username ?? "",
                    body: first.body,
                    filePath: first.position?.filePath,
                    line: first.position?.newLine ?? first.position?.oldLine,
                    isOnOldLine: first.position?.newLine == nil && first.position?.oldLine != nil,
                    replies: notes.dropFirst().map { MergeRequestNote(author: $0.author?.username ?? "", body: $0.body) }
                )
            }
        let jobs = request.headPipeline?.jobs?.nodes ?? []
        return MergeRequestDetails(
            description: request.description ?? "",
            threads: threads,
            failedJobs: jobs.compactMap { job in
                job.name.map { PipelineJob(name: $0, stage: job.stage?.name, webURL: job.webPath.flatMap { URL(string: "https://\(host)\($0)") }) }
            },
            pipelineDuration: request.headPipeline?.duration
        )
    }

    private static func noteID(_ globalID: String) -> Int? {
        globalID.split(separator: "/").last.flatMap { Int($0) }
    }

    private static func payload<Payload: Decodable>(_ data: Data) throws -> Payload {
        let response: Response<Payload> = try GlabMergeRequestParser.decode(data)
        guard let payload = response.data else {
            throw MergeRequestError.command(response.errors?.first?.message ?? "Empty answer from GitLab")
        }
        return payload
    }

    private static func summary(_ node: MergeRequestNode, host: String) -> MergeRequestSummary? {
        guard let iid = Int(node.iid) else { return nil }
        return MergeRequestSummary(
            iid: iid,
            title: node.title,
            state: GlabMergeRequestParser.state(node.state.lowercased()),
            isDraft: node.draft ?? false,
            webURL: node.webUrl.flatMap(URL.init(string:)),
            author: node.author?.username ?? "",
            sourceBranch: node.sourceBranch,
            targetBranch: node.targetBranch,
            hasConflicts: node.conflicts ?? false,
            detailedStatus: node.detailedMergeStatus.map { GlabMergeRequestParser.detail($0.lowercased()) },
            commentCount: node.userNotesCount ?? 0,
            updatedAt: node.updatedAt,
            pipeline: node.headPipeline.map { pipeline($0, host: host) },
            approvedBy: node.approvedBy?.nodes.map(\.username) ?? [],
            labels: node.labels?.nodes.map(\.title) ?? [],
            createdAt: node.createdAt,
            mergedAt: node.mergedAt,
            closedAt: node.closedAt,
            mergedBy: node.mergeUser?.username,
            commitCount: node.commitCount,
            diffStats: node.diffStatsSummary.map { DiffStats(additions: $0.additions, deletions: $0.deletions, fileCount: $0.fileCount) },
            threadCount: node.resolvableDiscussionsCount ?? 0,
            resolvedThreadCount: node.resolvedDiscussionsCount ?? 0,
            isBehindTarget: node.divergedFromTargetBranch ?? false,
            squashOnMerge: node.squashOnMerge ?? false,
            removesSourceBranch: node.shouldRemoveSourceBranch,
            headSHA: node.diffHeadSha,
            isAutoMergeEnabled: node.autoMergeEnabled ?? false,
            permissions: node.userPermissions.map { MergeRequestPermissions(canMerge: $0.canMerge, canApprove: $0.canApprove) } ?? .none
        )
    }

    private static func pipeline(_ pipeline: Pipeline, host: String) -> PipelineInfo {
        PipelineInfo(
            status: GlabMergeRequestParser.pipelineStatus(pipeline.status.lowercased()),
            webURL: pipeline.detailedStatus?.detailsPath.flatMap { URL(string: "https://\(host)\($0)") },
            updatedAt: pipeline.updatedAt,
            id: pipeline.detailedStatus?.detailsPath.flatMap { $0.split(separator: "/").last.flatMap { Int($0) } },
            duration: pipeline.duration,
            finishedAt: pipeline.finishedAt,
            failedJobCount: pipeline.failedJobsCount
        )
    }
}
