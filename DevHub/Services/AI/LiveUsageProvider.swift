import Foundation

nonisolated struct LiveUsageProvider: UsageProviding {
    let shell: ShellRunner
    let home: String

    func usage(for provider: UsageProviderID) async throws -> ProviderUsage? {
        switch provider {
        case .claude: try await claudeUsage()
        case .copilot: try await copilotUsage()
        }
    }

    private func claudeUsage() async throws -> ProviderUsage? {
        guard let text = try await claudeCredentialText() else { return nil }
        guard let credentials = ClaudeCredentialsParser.parse(text) else { throw UsageFailure.credentialsUnreadable("Claude") }
        guard credentials.isExpired == false else { throw UsageFailure.expired("Claude") }
        let (data, status) = try await UsageHTTP.get(
            URL(string: "https://api.anthropic.com/api/oauth/usage")!,
            headers: [
                "Authorization": "Bearer \(credentials.accessToken)",
                "anthropic-beta": "oauth-2025-04-20",
                "Accept": "application/json"
            ]
        )
        try Self.check(status, name: "Claude")
        let meters = ClaudeUsageParser.parse(data)
        guard meters.isEmpty == false else { throw UsageFailure.unreadable("Claude", keys: UsageNumber.fieldNames(data)) }
        return ProviderUsage(meters: meters, plan: credentials.plan, note: nil)
    }

    private func copilotUsage() async throws -> ProviderUsage? {
        guard let token = try await copilotToken() else { return nil }
        let (data, status) = try await UsageHTTP.get(
            URL(string: "https://api.github.com/copilot_internal/user")!,
            headers: ["Authorization": "token \(token)", "Accept": "application/json"]
        )
        try Self.check(status, name: "Copilot")
        guard let usage = CopilotUsageParser.parse(data) else { throw UsageFailure.unreadable("Copilot", keys: UsageNumber.fieldNames(data)) }
        return usage
    }

    private func claudeCredentialText() async throws -> String? {
        let result = try await shell.run("security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"], cwd: nil)
        if result.exitCode == 0, result.stdout.isEmpty == false {
            return result.stdout
        }
        return try? String(contentsOfFile: home + "/.claude/.credentials.json", encoding: .utf8)
    }

    private func copilotToken() async throws -> String? {
        let result = try await shell.run("security", ["find-generic-password", "-s", "copilot-cli", "-w"], cwd: nil)
        if result.exitCode == 0, let token = CopilotTokenParser.parse(result.stdout) {
            return token
        }
        guard hasGitHubCLI else { return nil }
        let fallback = try await shell.run("gh", ["auth", "token"], cwd: nil)
        guard fallback.exitCode == 0 else { return nil }
        return CopilotTokenParser.parse(fallback.stdout)
    }

    private var hasGitHubCLI: Bool {
        ["/opt/homebrew/bin/gh", "/usr/local/bin/gh", "/usr/bin/gh"].contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func check(_ status: Int, name: String) throws {
        switch status {
        case 200..<300: return
        case 401, 403: throw UsageFailure.rejected(name)
        default: throw UsageFailure.http(status)
        }
    }
}
