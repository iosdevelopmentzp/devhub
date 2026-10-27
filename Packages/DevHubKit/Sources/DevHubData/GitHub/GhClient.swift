import Foundation
import DevHubDomain

struct GhClient {
    struct Variable {
        let name: String
        let value: String
        let isTyped: Bool

        static func text(_ name: String, _ value: String) -> Variable {
            Variable(name: name, value: value, isTyped: false)
        }

        static func typed(_ name: String, _ value: String) -> Variable {
            Variable(name: name, value: value, isTyped: true)
        }

        var arguments: [String] {
            [isTyped ? "-F" : "-f", "\(name)=\(value)"]
        }
    }

    let shell: ShellRunner

    func graphql(_ query: String, variables: [Variable], host: CodeHost) async throws -> Data {
        try await run(Self.graphqlArguments(query: query, variables: variables, host: host.host), host: host)
    }

    func rest(_ endpoint: String, method: String, fields: [Variable], host: CodeHost) async throws -> Data {
        try await run(Self.restArguments(endpoint: endpoint, method: method, fields: fields, host: host.host), host: host)
    }

    func log(_ endpoint: String, host: CodeHost) async throws -> Data {
        try await run(Self.logArguments(endpoint: endpoint, host: host.host), host: host)
    }

    func pr(_ arguments: [String], host: CodeHost) async throws -> Data {
        try await run(["pr"] + arguments + ["--repo", Self.repository(host)], host: host)
    }

    func command(_ arguments: [String], host: CodeHost) async throws -> Data {
        try await run(arguments + ["--repo", Self.repository(host)], host: host)
    }

    static func graphqlArguments(query: String, variables: [Variable], host: String) -> [String] {
        ["api", "graphql", "--hostname", host, "-f", "query=\(query)"]
            + variables.flatMap(\.arguments)
    }

    static func restArguments(endpoint: String, method: String, fields: [Variable], host: String) -> [String] {
        ["api", "--hostname", host, "-X", method, endpoint] + fields.flatMap(\.arguments)
    }

    static func logArguments(endpoint: String, host: String) -> [String] {
        ["api", "--hostname", host, "--allow-escape-sequences", endpoint]
    }

    static func repository(_ host: CodeHost) -> String {
        host.host == "github.com" ? host.path : "\(host.host)/\(host.path)"
    }

    static func owner(_ host: CodeHost) -> String {
        String(host.path.split(separator: "/").first ?? "")
    }

    static func name(_ host: CodeHost) -> String {
        host.path.split(separator: "/").dropFirst().joined(separator: "/")
    }

    private func run(_ arguments: [String], host: CodeHost) async throws -> Data {
        guard host.kind == .github else { throw PullRequestError.noCodeHost }
        let result: ShellResult
        do {
            result = try await shell.run("gh", arguments, cwd: nil)
        } catch {
            throw PullRequestError.notInstalled(tool: "gh")
        }
        guard result.exitCode == 0 else {
            throw CodeHostErrorMapper.error(tool: "gh", exitCode: result.exitCode, message: result.failureMessage, host: host.host)
        }
        return Data(result.stdout.utf8)
    }
}
