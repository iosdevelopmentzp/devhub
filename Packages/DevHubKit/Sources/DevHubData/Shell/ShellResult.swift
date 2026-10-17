import Foundation
import DevHubDomain

struct ShellResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var failureMessage: String {
        let message = stderr.trimmed.isEmpty ? stdout.trimmed : stderr.trimmed
        return message.isEmpty ? "Exited with code \(exitCode)." : message
    }
}
