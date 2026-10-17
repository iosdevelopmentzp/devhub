import Foundation
import DevHubDomain

struct GlabClient {
    let shell: ShellRunner

    func rest(_ endpoint: String, host: String) async throws -> Data {
        try await run(["api", "--hostname", host, endpoint], host: host)
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
            + variables.flatMap { ["-f", "\($0.name)=\($0.value)"] }
    }

    static func host(of repository: URL) throws -> String {
        guard let host = repository.host(), host.contains("github") == false else { throw MergeRequestError.notGitLab }
        return host
    }

    static func projectPath(of repository: URL) -> String {
        repository.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    private func run(_ arguments: [String], host: String) async throws -> Data {
        let result: ShellResult
        do {
            result = try await shell.run("glab", arguments, cwd: nil)
        } catch {
            throw MergeRequestError.notInstalled
        }
        guard result.exitCode == 0 else {
            throw GlabErrorMapper.error(exitCode: result.exitCode, message: result.failureMessage, host: host)
        }
        return Data(result.stdout.utf8)
    }
}
