import Foundation
import DevHubDomain
import DevHubUI

enum TrackerToolMapper {
    static func model(for state: TrackerToolState?, isChecking: Bool) -> TrackerToolModel {
        switch state {
        case nil:
            return TrackerToolModel(icon: "magnifyingglass", tint: .secondary, title: "Looking for jira…", detail: "", command: nil, showsCheckAgain: false, isWorking: true, isCompact: true)
        case .ready(let version, let user):
            let title = ["jira", version].compactMap { $0 }.joined(separator: " ")
            return TrackerToolModel(icon: "checkmark.circle.fill", tint: .green, title: title, detail: user ?? "", command: nil, showsCheckAgain: false, isWorking: isChecking, isCompact: true)
        case .missing:
            return TrackerToolModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "jira is not installed",
                detail: "DevHub reads Jira through jira-cli. Install it with Homebrew, then run jira init in Terminal.",
                command: TrackerText.installCommand,
                showsCheckAgain: true,
                isWorking: isChecking,
                isCompact: false
            )
        case .notConfigured:
            return TrackerToolModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "jira is not set up",
                detail: "Run jira init in Terminal. It asks for the installation type (Cloud or Local), the server, your login, the authentication type and the default project. With a personal access token on Jira Server or Data Center, choose bearer.",
                command: TrackerText.setupCommand,
                showsCheckAgain: true,
                isWorking: isChecking,
                isCompact: false
            )
        case .notLoggedIn:
            return TrackerToolModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "jira cannot log in",
                detail: "jira found no token, or the server did not accept it. jira reads the token from the keychain item jira-cli (the account is the login in ~/.config/.jira/.config.yml), from ~/.netrc, or from JIRA_API_TOKEN. DevHub passes JIRA_API_TOKEN and JIRA_AUTH_TYPE from ~/.zshrc to jira and never stores them. A personal access token on Jira Server needs auth_type: bearer in the config. The command below asks for the token, so it does not stay in the shell history.",
                command: TrackerText.tokenCommand,
                showsCheckAgain: true,
                isWorking: isChecking,
                isCompact: false
            )
        case .failed(let message):
            return TrackerToolModel(
                icon: "xmark.octagon.fill",
                tint: .red,
                title: "jira failed",
                detail: message,
                command: nil,
                showsCheckAgain: true,
                isWorking: isChecking,
                isCompact: false
            )
        }
    }
}
