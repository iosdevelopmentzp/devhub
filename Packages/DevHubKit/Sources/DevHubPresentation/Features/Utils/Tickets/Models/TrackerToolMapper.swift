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
                detail: "Run jira init in Terminal. It asks for the installation type, the server, your login and the default project. Put the API token into the keychain first: an item named jira-cli with your login as the account.",
                command: TrackerText.setupCommand,
                showsCheckAgain: true,
                isWorking: isChecking,
                isCompact: false
            )
        case .notLoggedIn:
            return TrackerToolModel(
                icon: "exclamationmark.triangle.fill",
                tint: .orange,
                title: "jira has no API token",
                detail: "Create an API token in your Atlassian account, then add it to the keychain with the command below (or to ~/.netrc). DevHub never reads the token itself.",
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
