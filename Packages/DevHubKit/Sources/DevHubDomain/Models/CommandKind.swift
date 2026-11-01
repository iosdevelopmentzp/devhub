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
    private static let plainReads: Set<String> = ["du", "ps", "grep", "plutil", "pgrep", "mdfind", "xcode-select"]
    private static let codeHostReads: Set<String> = ["view", "list", "checks", "diff", "status"]
    private static let circleCIReads: Set<String> = ["run list", "run get", "workflow get", "workflow list", "job get", "job output", "testresult list", "setting list", "version", "auth me"]

    package static func classify(_ executable: String, _ arguments: [String]) -> CommandKind {
        switch executable {
        case "security":
            return .secret
        case "gh":
            if arguments.starts(with: ["auth", "token"]) { return .secret }
            return codeHostKind(arguments)
        case "git":
            return gitKind(arguments)
        case "xcrun":
            guard arguments.first == "simctl", arguments.count > 1 else { return .action }
            if simctlReads.contains(arguments[1]) { return .read }
            if arguments[1] == "spawn", arguments.contains("read") { return .read }
            if arguments[1] == "spawn", arguments.contains("log") { return .appLog }
            return .action
        case "glab":
            return codeHostKind(arguments)
        case "circleci":
            return circleCIKind(arguments)
        case "xcodebuild":
            return arguments.contains("-showBuildSettings") ? .read : .action
        case "osascript":
            return arguments.joined().contains("click ") || arguments.joined().contains("set active run destination") ? .action : .read
        default:
            return plainReads.contains(executable) ? .read : .action
        }
    }

    private static func circleCIKind(_ arguments: [String]) -> CommandKind {
        let words = arguments.filter { $0.hasPrefix("-") == false }
        if words.first == "api" {
            let writes = arguments.contains { ["-X", "--method", "-f", "--field", "-d", "--data"].contains($0) }
            return writes ? .action : .read
        }
        let pair = words.prefix(2).joined(separator: " ")
        return circleCIReads.contains(pair) || circleCIReads.contains(words.first ?? "") ? .read : .action
    }

    private static func codeHostKind(_ arguments: [String]) -> CommandKind {
        guard arguments.first == "api" else {
            return arguments.count > 1 && codeHostReads.contains(arguments[1]) ? .read : .action
        }
        if arguments.contains("graphql") {
            let query = arguments.first { $0.hasPrefix("query=") } ?? ""
            return query.dropFirst("query=".count).trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("mutation") ? .action : .read
        }
        if let index = arguments.firstIndex(where: { $0 == "-X" || $0 == "--method" }), index + 1 < arguments.count {
            return arguments[index + 1].uppercased() == "GET" ? .read : .action
        }
        let sendsFields = arguments.contains { ["-f", "-F", "--field", "--raw-field", "--input"].contains($0) }
        return sendsFields ? .action : .read
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
