import Foundation
import DevHubDomain

enum CodeHostErrorMapper {
    static func error(tool: String, exitCode: Int32, message: String, host: String) -> PullRequestError {
        if exitCode == 127 || message.contains("command not found") || message.contains("No such file") {
            return .notInstalled(tool: tool)
        }
        if let scope = missingScope(in: message) {
            return .missingScope(tool: tool, host: host, scope: scope)
        }
        if message.contains("401") || message.localizedCaseInsensitiveContains("token") || message.localizedCaseInsensitiveContains("auth") {
            return .notLoggedIn(tool: tool, host: host)
        }
        return .command(message)
    }

    static func missingScope(in message: String) -> String? {
        guard message.contains("INSUFFICIENT_SCOPES") || message.contains("not been granted the required scopes") else { return nil }
        guard let start = message.range(of: "scopes: ['")?.upperBound, let end = message[start...].range(of: "'")?.lowerBound else { return "notifications" }
        return String(message[start..<end])
    }
}
