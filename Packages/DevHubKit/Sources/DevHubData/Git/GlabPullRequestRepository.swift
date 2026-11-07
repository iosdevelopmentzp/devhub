import Foundation
import DevHubDomain

struct GlabPullRequestRepository: CodeHostRepository {
    let client: GlabClient

    func status(branch: String, repository: CodeHost) async throws -> PullRequestStatus {
        let host = try GlabClient.host(of: repository)
        let project = Self.encoded(GlabClient.projectPath(of: repository))
        let ref = Self.encoded(branch)
        async let request = GlabPullRequestParser.mergeRequest(
            from: client.rest("projects/\(project)/merge_requests?source_branch=\(ref)&state=all&order_by=updated_at&per_page=5", host: host)
        )
        async let pipeline = GlabPullRequestParser.pipeline(
            from: client.rest("projects/\(project)/pipelines?ref=\(ref)&per_page=1&order_by=id", host: host)
        )
        let (loadedRequest, loadedPipeline) = try await (request, pipeline)
        return PullRequestStatus(pullRequest: loadedRequest, pipeline: loadedPipeline)
    }

    func list(_ query: PullRequestQuery, after cursor: String?, repository: CodeHost) async throws -> PullRequestList {
        let host = try GlabClient.host(of: repository)
        let data = try await client.graphql(
            GlabGraphQLQueries.list(query.scope),
            variables: GlabGraphQLQueries.listVariables(query, after: cursor, projectPath: GlabClient.projectPath(of: repository)),
            host: host
        )
        return try GlabGraphQLParser.list(from: data, host: host)
    }

    func openRequests(repository: CodeHost) async throws -> PullRequestList {
        try await list(PullRequestQuery(scope: .all, state: .opened), after: nil, repository: repository)
    }

    func details(iid: Int, repository: CodeHost) async throws -> PullRequestDetails {
        let host = try GlabClient.host(of: repository)
        let data = try await client.graphql(
            GlabGraphQLQueries.details,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository)), (name: "iid", value: String(iid))],
            host: host
        )
        return try GlabGraphQLParser.details(from: data, host: host)
    }

    func diffs(iid: Int, repository: CodeHost) async throws -> [PullRequestFileDiff] {
        let host = try GlabClient.host(of: repository)
        let project = Self.encoded(GlabClient.projectPath(of: repository))
        return try await GlabDiffParser.files(from: client.rest("projects/\(project)/merge_requests/\(iid)/diffs?per_page=100", host: host))
    }

    func approve(iid: Int, repository: CodeHost) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/approve", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func unapprove(iid: Int, repository: CodeHost) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/unapprove", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func setDraft(iid: Int, isDraft: Bool, repository: CodeHost) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.setDraft,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository)), (name: "iid", value: String(iid)), (name: "draft", value: isDraft ? "true" : "false")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func rebase(iid: Int, repository: CodeHost) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/rebase", method: "PUT", fields: [], host: try GlabClient.host(of: repository))
    }

    func retryPipeline(id: Int, repository: CodeHost) async throws {
        let project = Self.encoded(GlabClient.projectPath(of: repository))
        _ = try await client.rest("projects/\(project)/pipelines/\(id)/retry", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/merge",
            method: "PUT",
            fields: [(name: "squash", value: squash ? "true" : "false"), (name: "should_remove_source_branch", value: removeSourceBranch ? "true" : "false")],
            host: try GlabClient.host(of: repository)
        )
    }

    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
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

    func cancelAutoMerge(iid: Int, repository: CodeHost) async throws {
        _ = try await client.rest("\(mergeRequest(iid, repository))/cancel_merge_when_pipeline_succeeds", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    func cancelPipeline(id: Int, repository: CodeHost) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.cancelPipeline,
            variables: [(name: "id", value: "gid://gitlab/Ci::Pipeline/\(id)")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func create(_ request: NewPullRequest, repository: CodeHost) async throws -> PullRequestSummary {
        let project = Self.encoded(GlabClient.projectPath(of: repository))
        let data = try await client.rest("projects/\(project)/merge_requests", method: "POST", fields: Self.createFields(request), host: try GlabClient.host(of: repository))
        return try GlabCreatedPullRequestParser.summary(from: data)
    }

    static func createFields(_ request: NewPullRequest) -> [(name: String, value: String)] {
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

    func labels(repository: CodeHost) async throws -> [String] {
        let data = try await client.graphql(
            GlabGraphQLQueries.labels,
            variables: [(name: "path", value: GlabClient.projectPath(of: repository))],
            host: try GlabClient.host(of: repository)
        )
        return try GlabGraphQLParser.labels(from: data)
    }

    func people(repository: CodeHost) async throws -> [String] {
        let endpoint = "projects/\(Self.encoded(GlabClient.projectPath(of: repository)))/members/all?per_page=100"
        return try await GlabMemberListParser.usernames(from: client.paged(endpoint, host: try GlabClient.host(of: repository)))
    }

    func teams(repository: CodeHost) async throws -> [String] {
        []
    }

    func myTeams(repository: CodeHost) async throws -> [String] {
        []
    }

    func updatePeople(iid: Int, role: PullRequestPersonRole, add: [String], remove: [String], repository: CodeHost) async throws {
        _ = try await client.command(Self.peopleArguments(iid: iid, role: role, add: add, remove: remove), repository: repository)
    }

    static func peopleArguments(iid: Int, role: PullRequestPersonRole, add: [String], remove: [String]) -> [String] {
        let flag = role == .reviewer ? "--reviewer" : "--assignee"
        return ["mr", "update", String(iid)]
            + add.map { "\(flag)=+\($0)" }
            + remove.map { "\(flag)=!\($0)" }
    }

    func resolveThread(id: String, repository: CodeHost) async throws {
        let data = try await client.graphql(
            GlabGraphQLQueries.toggleResolve,
            variables: [(name: "id", value: id), (name: "resolve", value: "true")],
            host: try GlabClient.host(of: repository)
        )
        try GlabGraphQLParser.mutation(from: data)
    }

    func reply(threadID: String, body: String, iid: Int, repository: CodeHost) async throws {
        let discussion = threadID.split(separator: "/").last.map(String.init) ?? threadID
        let text = body.hasPrefix("@") ? " " + body : body
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/discussions/\(Self.encoded(discussion))/notes",
            method: "POST",
            fields: [(name: "body", value: text)],
            host: try GlabClient.host(of: repository)
        )
    }

    func comment(iid: Int, body: String, repository: CodeHost) async throws {
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/notes",
            method: "POST",
            fields: Self.commentFields(body: body),
            host: try GlabClient.host(of: repository)
        )
    }

    func requestChanges(iid: Int, body: String, repository: CodeHost) async throws {
        throw PullRequestError.command("GitLab has no Request Changes review. Write a comment instead.")
    }

    func addLineComment(iid: Int, comment: PullRequestLineComment, repository: CodeHost) async throws {
        let host = try GlabClient.host(of: repository)
        let refs = try await GlabDiffRefsParser.diffRefs(from: client.rest(mergeRequest(iid, repository), host: host))
        _ = try await client.rest(
            "\(mergeRequest(iid, repository))/discussions",
            method: "POST",
            fields: Self.lineCommentFields(comment, refs: refs),
            host: host
        )
    }

    func jobLog(jobID: String, repository: CodeHost) async throws -> String {
        JobLogTail.text(from: try await client.rest(job(jobID, repository) + "/trace", host: try GlabClient.host(of: repository)))
    }

    func retryJob(jobID: String, repository: CodeHost) async throws {
        _ = try await client.rest(job(jobID, repository) + "/retry", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    private func job(_ jobID: String, _ repository: CodeHost) -> String {
        "projects/\(Self.encoded(GlabClient.projectPath(of: repository)))/jobs/\(Self.encoded(jobID))"
    }

    func fileContent(path: String, ref: String, repository: CodeHost) async throws -> String {
        let host = try GlabClient.host(of: repository)
        return String(decoding: try await client.rest(Self.fileContentEndpoint(path: path, ref: ref, project: GlabClient.projectPath(of: repository)), host: host), as: UTF8.self)
    }

    func inbox(repository: CodeHost) async throws -> [InboxItem] {
        let host = try GlabClient.host(of: repository)
        return try GlabInboxParser.items(from: try await client.rest(Self.inboxEndpoint, host: host), projectPath: GlabClient.projectPath(of: repository))
    }

    func markInboxDone(id: String, repository: CodeHost) async throws {
        _ = try await client.rest("todos/\(Self.encoded(id))/mark_as_done", method: "POST", fields: [], host: try GlabClient.host(of: repository))
    }

    static let inboxEndpoint = "todos?state=pending&per_page=50"

    static func fileContentEndpoint(path: String, ref: String, project: String) -> String {
        "projects/\(Self.encoded(project))/repository/files/\(Self.encoded(path))/raw?ref=\(Self.encoded(ref))"
    }

    static func lineCommentFields(_ comment: PullRequestLineComment, refs: GlabDiffRefsParser.DiffRefs) -> [(name: String, value: String)] {
        var fields: [(name: String, value: String)] = commentFields(body: comment.body) + [
            (name: "position[position_type]", value: "text"),
            (name: "position[base_sha]", value: refs.baseSHA),
            (name: "position[start_sha]", value: refs.startSHA),
            (name: "position[head_sha]", value: refs.headSHA),
            (name: "position[old_path]", value: comment.oldPath),
            (name: "position[new_path]", value: comment.path),
        ]
        if let line = comment.newLine {
            fields.append((name: "position[new_line]", value: String(line)))
        }
        if let line = comment.oldLine {
            fields.append((name: "position[old_line]", value: String(line)))
        }
        return fields
    }

    static func commentFields(body: String) -> [(name: String, value: String)] {
        [(name: "body", value: body.hasPrefix("@") ? " " + body : body)]
    }

    private func mergeRequest(_ iid: Int, _ repository: CodeHost) -> String {
        "projects/\(Self.encoded(GlabClient.projectPath(of: repository)))/merge_requests/\(iid)"
    }

    private static func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }
}
