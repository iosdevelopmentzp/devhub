import Foundation
import DevHubDomain

struct GhMergeRequestRepository: MergeRequestRepository {
    let client: GhClient

    func status(branch: String, repository: CodeHost) async throws -> MergeRequestStatus {
        let data = try await client.graphql(
            GhGraphQLQueries.status,
            variables: Self.repositoryVariables(repository) + [.text("branch", branch), .text("ref", "refs/heads/\(branch)")],
            host: repository
        )
        return try GhPullRequestParser.status(from: data)
    }

    func list(_ query: MergeRequestQuery, after cursor: String?, repository: CodeHost) async throws -> MergeRequestList {
        let data = try await client.graphql(GhGraphQLQueries.list, variables: Self.listVariables(query, after: cursor, repository: repository), host: repository)
        return try GhPullRequestParser.list(from: data)
    }

    static func listVariables(_ query: MergeRequestQuery, after cursor: String?, repository: CodeHost) -> [GhClient.Variable] {
        let search = GhGraphQLQueries.search(query, repository: repository.path)
        return [.text("search", search)] + repositoryVariables(repository) + (cursor.map { [.text("after", $0)] } ?? [])
    }

    func openRequests(repository: CodeHost) async throws -> MergeRequestList {
        try await list(MergeRequestQuery(scope: .all, state: .opened), after: nil, repository: repository)
    }

    func details(iid: Int, repository: CodeHost) async throws -> MergeRequestDetails {
        let data = try await client.graphql(GhGraphQLQueries.details, variables: Self.pullRequestVariables(iid, repository), host: repository)
        return try GhPullRequestParser.details(from: data)
    }

    func diffs(iid: Int, repository: CodeHost) async throws -> [MergeRequestFileDiff] {
        try await GhDiffParser.files(from: client.rest("\(pull(iid, repository))/files?per_page=100", method: "GET", fields: [], host: repository))
    }

    func approve(iid: Int, repository: CodeHost) async throws {
        _ = try await client.pr(["review", String(iid), "--approve"], host: repository)
    }

    func unapprove(iid: Int, repository: CodeHost) async throws {
        let data = try await client.graphql(GhGraphQLQueries.myApproval, variables: Self.pullRequestVariables(iid, repository), host: repository)
        guard let reviewID = try GhPullRequestParser.myApprovalID(from: data) else {
            throw MergeRequestError.command("You have not approved #\(iid)")
        }
        try await mutate(GhGraphQLQueries.dismissReview, [.text("id", reviewID), .text("message", "Approval taken back")], repository)
    }

    func setDraft(iid: Int, isDraft: Bool, repository: CodeHost) async throws {
        _ = try await client.pr(["ready", String(iid)] + (isDraft ? ["--undo"] : []), host: repository)
    }

    func rebase(iid: Int, repository: CodeHost) async throws {
        _ = try await client.rest("\(pull(iid, repository))/update-branch", method: "PUT", fields: [], host: repository)
    }

    func retryPipeline(id: Int, repository: CodeHost) async throws {
        _ = try await client.command(["run", "rerun", String(id), "--failed"], host: repository)
    }

    func merge(iid: Int, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
        _ = try await client.pr(Self.mergeArguments(iid: iid, squash: squash, removeSourceBranch: removeSourceBranch), host: repository)
    }

    func setAutoMerge(iid: Int, sha: String, squash: Bool, removeSourceBranch: Bool, repository: CodeHost) async throws {
        let arguments = Self.mergeArguments(iid: iid, squash: squash, removeSourceBranch: removeSourceBranch) + ["--auto", "--match-head-commit", sha]
        _ = try await client.pr(arguments, host: repository)
    }

    static func mergeArguments(iid: Int, squash: Bool, removeSourceBranch: Bool) -> [String] {
        ["merge", String(iid), squash ? "--squash" : "--merge"] + (removeSourceBranch ? ["--delete-branch"] : [])
    }

    func cancelAutoMerge(iid: Int, repository: CodeHost) async throws {
        _ = try await client.pr(["merge", String(iid), "--disable-auto"], host: repository)
    }

    func cancelPipeline(id: Int, repository: CodeHost) async throws {
        _ = try await client.command(["run", "cancel", String(id)], host: repository)
    }

    func create(_ request: NewMergeRequest, repository: CodeHost) async throws -> MergeRequestSummary {
        let data = try await client.rest("repos/\(repository.path)/pulls", method: "POST", fields: Self.createFields(request), host: repository)
        let summary = try GhCreatedPullRequestParser.summary(from: data, labels: request.labels)
        guard request.labels.isEmpty == false else { return summary }
        _ = try await client.rest("repos/\(repository.path)/issues/\(summary.iid)/labels", method: "POST", fields: request.labels.map { .text("labels[]", $0) }, host: repository)
        return summary
    }

    static func createFields(_ request: NewMergeRequest) -> [GhClient.Variable] {
        [
            .text("head", request.sourceBranch),
            .text("base", request.targetBranch),
            .text("title", request.title),
            .text("body", request.description),
            .typed("draft", request.isDraft ? "true" : "false"),
        ]
    }

    func labels(repository: CodeHost) async throws -> [String] {
        try await GhPullRequestParser.labels(from: client.command(["label", "list", "--json", "name", "--limit", "200"], host: repository))
    }

    func resolveThread(id: String, repository: CodeHost) async throws {
        try await mutate(GhGraphQLQueries.resolveThread, [.text("id", id)], repository)
    }

    func reply(threadID: String, body: String, iid: Int, repository: CodeHost) async throws {
        try await mutate(GhGraphQLQueries.reply, [.text("id", threadID), .text("body", body)], repository)
    }

    private func mutate(_ query: String, _ variables: [GhClient.Variable], _ repository: CodeHost) async throws {
        try await GhPullRequestParser.mutation(from: client.graphql(query, variables: variables, host: repository))
    }

    private func pull(_ iid: Int, _ repository: CodeHost) -> String {
        "repos/\(repository.path)/pulls/\(iid)"
    }

    private static func repositoryVariables(_ repository: CodeHost) -> [GhClient.Variable] {
        [.text("owner", GhClient.owner(repository)), .text("name", GhClient.name(repository))]
    }

    private static func pullRequestVariables(_ iid: Int, _ repository: CodeHost) -> [GhClient.Variable] {
        repositoryVariables(repository) + [.typed("number", String(iid))]
    }
}
