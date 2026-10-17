import Foundation
import DevHubDomain

enum CodeHostErrorMapper {
    static func error(tool: String, exitCode: Int32, message: String, host: String) -> PullRequestError {
        if exitCode == 127 || message.contains("command not found") || message.contains("No such file") {
            return .notInstalled(tool: tool)
        }
        if message.contains("401") || message.localizedCaseInsensitiveContains("token") || message.localizedCaseInsensitiveContains("auth") {
            return .notLoggedIn(tool: tool, host: host)
        }
        return .command(message)
    }
}
