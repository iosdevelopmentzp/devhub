import Foundation
import DevHubDomain

enum GlabErrorMapper {
    static func error(exitCode: Int32, message: String, host: String) -> MergeRequestError {
        if exitCode == 127 || message.contains("command not found") || message.contains("No such file") {
            return .notInstalled
        }
        if message.contains("401") || message.localizedCaseInsensitiveContains("token") || message.localizedCaseInsensitiveContains("auth") {
            return .notLoggedIn(host: host)
        }
        return .command(message)
    }
}
