import Foundation
import DevHubDomain

struct GlabClient {
    let shell: ShellRunner

    func rest(_ endpoint: String, host: String) async throws -> Data {
        try await run(["api", "--hostname", host, endpoint], host: host)
    }

    func paged(_ endpoint: String, host: String) async throws -> Data {
        try await run(Self.pagedArguments(endpoint: endpoint, host: host), host: host)
    }

    static func pagedArguments(endpoint: String, host: String) -> [String] {
        ["api", "--hostname", host, "--paginate", endpoint]
    }

    func rest(_ endpoint: String, method: String, fields: [(name: String, value: String)], host: String) async throws -> Data {
        try await run(Self.restArguments(endpoint: endpoint, method: method, fields: fields, host: host), host: host)
    }

    static func restArguments(endpoint: String, method: String, fields: [(name: String, value: String)], host: String) -> [String] {
        ["api", "--hostname", host, "-X", method, endpoint] + fields.flatMap { ["-f", "\($0.name)=\($0.value)"] }
    }

    func graphql(_ query: String, variables: [(name: String, value: String)], host: String) async throws -> Data {
        try await run(Self.graphqlArguments(query: query, variables: variables, host: host), host: host)
    }

    static func graphqlArguments(query: String, variables: [(name: String, value: String)], host: String) -> [String] {
        ["api", "graphql", "--hostname", host, "-f", "query=\(query)"]
            + variables.flatMap { [booleans.contains($0.value) ? "-F" : "-f", "\($0.name)=\($0.value)"] }
    }

    private static let booleans: Set<String> = ["true", "false"]

    func command(_ arguments: [String], repository: CodeHost) async throws -> Data {
        try await run(Self.commandArguments(arguments, repository: repository), host: try Self.host(of: repository))
    }

    static func commandArguments(_ arguments: [String], repository: CodeHost) -> [String] {
        arguments + ["--repo", repository.webURL.absoluteString]
    }

    static func host(of repository: CodeHost) throws -> String {
        guard repository.kind == .gitlab else { throw PullRequestError.noCodeHost }
        return repository.host
    }

    static func projectPath(of repository: CodeHost) -> String {
        repository.path
    }

    private func run(_ arguments: [String], host: String) async throws -> Data {
        let result: ShellResult
        do {
            result = try await shell.run("glab", arguments, cwd: nil)
        } catch {
            throw PullRequestError.notInstalled(tool: "glab")
        }
        guard result.exitCode == 0 else {
            throw CodeHostErrorMapper.error(tool: "glab", exitCode: result.exitCode, message: result.failureMessage, host: host)
        }
        return Data(result.stdout.utf8)
    }
}
