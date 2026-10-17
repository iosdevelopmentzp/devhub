import Foundation
import DevHubDomain

struct GlabMergeRequestRepository: MergeRequestRepository {
    let client: GlabClient

    func status(branch: String, repository: URL) async throws -> MergeRequestStatus {
        let host = try GlabClient.host(of: repository)
        let project = encoded(GlabClient.projectPath(of: repository))
        let ref = encoded(branch)
        async let request = GlabMergeRequestParser.mergeRequest(
            from: client.rest("projects/\(project)/merge_requests?source_branch=\(ref)&state=all&order_by=updated_at&per_page=5", host: host)
        )
        async let pipeline = GlabMergeRequestParser.pipeline(
            from: client.rest("projects/\(project)/pipelines?ref=\(ref)&per_page=1&order_by=id", host: host)
        )
        let (loadedRequest, loadedPipeline) = try await (request, pipeline)
        return MergeRequestStatus(mergeRequest: loadedRequest, pipeline: loadedPipeline)
    }

    func list(_ query: MergeRequestQuery, after cursor: String?, repository: URL) async throws -> MergeRequestList {
        let host = try GlabClient.host(of: repository)
        let data = try await client.graphql(
            GlabGraphQLQueries.list(query.scope),
            variables: GlabGraphQLQueries.listVariables(query, after: cursor, projectPath: GlabClient.projectPath(of: repository)),
            host: host
        )
        return try GlabGraphQLParser.list(from: data, host: host)
    }

    func openRequests(repository: URL) async throws -> MergeRequestList {
        try await list(MergeRequestQuery(scope: .all, state: .opened), after: nil, repository: repository)
    }

    func details(iid: Int, repository: URL) async throws -> MergeRequestDetails {
        let host = try GlabClient.host(of: repository)
        let data = try await client.graphql(
            GlabGraphQLQueries.details,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository)), (name: "iid", value: String(iid))],
            host: host
        )
        return try GlabGraphQLParser.details(from: data, host: host)
    }

    func diffs(iid: Int, repository: URL) async throws -> [MergeRequestFileDiff] {
        let host = try GlabClient.host(of: repository)
        let project = encoded(GlabClient.projectPath(of: repository))
        return try await GlabDiffParser.files(from: client.rest("projects/\(project)/merge_requests/\(iid)/diffs?per_page=100", host: host))
    }

    func approve(iid: Int, repository: URL) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/approve", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func unapprove(iid: Int, repository: URL) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/unapprove", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func setDraft(iid: Int, isDraft: Bool, repository: URL) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.setDraft,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository)), (name: "iid", value: String(iid)), (name: "draft", value: isDraft ? "true" : "false")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func rebase(iid: Int, repository: URL) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/rebase", method: "PUT", fields: [], host: try GlabClient.host(of: repository))
    }

    func retryPipeline(id: Int, repository: URL) async throws {
        let project = encoded(GlabClient.projectPath(of: repository))
        _ = try await client.rest("projects/\(project)/pipelines/\(id)/retry", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/merge",
            method: "PUT",
            fields: [(name: "squash", value: squash ? "true" : "false"), (name: "should_remove_source_branch", value: removeSourceBranch ? "true" : "false")],
            host: try GlabClient.host(of: repository)
        )
    }

    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: URL) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.setAutoMerge,
            variables: Self.autoMergeVariables(iid: iid, sha: sha, squash: squash, removeSourceBranch: removeSourceBranch, projectPath: GlabClient.projectPath(of: repository)),
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    static func autoMergeVariables(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, projectPath: String) -> [(name: String, value: String)] {
        [
            (name: "path", value: projectPath),
            (name: "iid", value: String(iid)),
            (name: "sha", value: sha),
            (name: "squash", value: squash ? "true" : "false"),
            (name: "remove", value: removeSourceBranch ? "true" : "false"),
        ]
    }

    func cancelAutoMerge(iid: Int, repository: URL) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/cancel_merge_when_pipeline_succeeds", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func cancelPipeline(id: Int, repository: URL) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.cancelPipeline,
            variables: [(name: "id", value: "gid://gitlab/Ci::Pipeline/\(id)")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func create(_ request: NewMergeRequest, repository: URL) async throws -> MergeRequestSummary {
        let project = encoded(GlabClient.projectPath(of: repository))
        let data = try await client.rest("projects/\(project)/merge_requests", method: "POST", fields: Self.createFields(request), host: try GlabClient.host(of: repository))
        return try GlabCreatedMergeRequestParser.summary(from: data)
    }

    static func createFields(_ request: NewMergeRequest) -> [(name: String, value: String)] {
        let title = request.isDraft && request.title.hasPrefix("Draft:") == false ? "Draft: \(request.title)" : request.title
        var fields = [
            (name: "source_branch", value: request.sourceBranch),
            (name: "target_branch", value: request.targetBranch),
            (name: "title", value: title),
            (name: "description", value: request.description),
            (name: "remove_source_branch", value: request.removeSourceBranch ? "true" : "false"),
            (name: "squash", value: request.squash ? "true" : "false"),
        ]
        if request.labels.isEmpty == false {
            fields.append((name: "labels", value: request.labels.joined(separator: ",")))
        }
        return fields.map { (name: $0.name, value: fieldValue($0.value)) }
    }

    private static func fieldValue(_ value: String) -> String {
        value.hasPrefix("@") ? " " + value : value
    }

    func labels(repository: URL) async throws -> [String] {
        let data = try await client.graphql(
            GlabGraphQLQueries.labels,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository))],
            host: try GlabClient.host(of: repository)
        )
        return try GlabGraphQLParser.labels(from: data)
    }

    func resolveThread(id: String, repository: URL) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.toggleResolve,
            variables: [(name: "id", value: id), (name: "resolve", value: "true")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func reply(threadID: String, body: String, iid: Int, repository: URL) async throws {
        let discussion = threadID.split(separator: "/").last.map(String.init) ?? threadID
        let text = body.hasPrefix("@") ? " " + body : body
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/discussions/\(encoded(discussion))/notes",
            method: "POST",
            fields: [(name: "body", value: text)],
            host: try GlabClient.host(of: repository)
        )
    }

    private func mergeRequest(_ iid: Int, _ repository: URL) -> String {
        "projects/\(encoded(GlabClient.projectPath(of: repository)))/merge_requests/\(iid)"
    }

    private func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }
}
