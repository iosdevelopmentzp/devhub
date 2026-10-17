import Foundation

package enum CommandKind: Sendable {
    case action
    case read
    case secret
    case appLog

    package var hidesOutput: Bool {
        self == .secret || self == .appLog
    }

    private static let gitReads: Set<String> = [
        "status", "log", "for-each-ref", "rev-parse", "symbolic-ref", "check-ref-format", "reflog",
        "rev-list", "show-ref", "config", "diff", "cherry", "merge-base", "ls-remote", "remote", "show"
    ]
    private static let simctlReads: Set<String> = ["list", "get_app_container", "listapps", "bootstatus"]
    private static let plainReads: Set<String> = ["du", "ps", "grep", "plutil", "pgrep"]

    package static func classify(_ executable: String, _ arguments: [String]) -> CommandKind {
        switch executable {
        case "security":
            return .secret
        case "git":
            return gitKind(arguments)
        case "xcrun":
            guard arguments.first == "simctl", arguments.count > 1 else { return .action }
            if simctlReads.contains(arguments[1]) { return .read }
            if arguments[1] == "spawn", arguments.contains("read") { return .read }
            if arguments[1] == "spawn", arguments.contains("log") { return .appLog }
            return .action
        case "glab":
            return arguments.first == "api" ? .read : .action
        case "xcodebuild":
            return arguments.contains("-showBuildSettings") ? .read : .action
        case "osascript":
            return arguments.joined().contains("click ") || arguments.joined().contains("set active run destination") ? .action : .read
        default:
            return plainReads.contains(executable) ? .read : .action
        }
    }

    private static func gitKind(_ arguments: [String]) -> CommandKind {
        let subcommand = arguments.first { $0.hasPrefix("-") == false && $0 != "-C" } ?? ""
        if gitReads.contains(subcommand) { return .read }
        if subcommand == "worktree", arguments.contains("list") { return .read }
        if subcommand == "stash", arguments.contains("list") { return .read }
        if subcommand == "branch" {
            let mutating: Set<String> = ["-d", "-D", "-m", "-M", "--delete", "--move", "-u", "--set-upstream-to"]
            return arguments.contains(where: mutating.contains) ? .action : .read
        }
        return .action
    }
}
