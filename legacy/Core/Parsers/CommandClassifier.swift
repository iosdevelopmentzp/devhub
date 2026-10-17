import Foundation

nonisolated enum CommandClassifier {
    private static let readGitSubcommands: Set<String> = [
        "status", "log", "for-each-ref", "rev-parse", "symbolic-ref", "reflog", "rev-list",
        "show-ref", "check-ref-format", "config", "diff", "merge-base", "ls-remote", "show", "cat-file", "describe"
    ]
    private static let writingBranchFlags: Set<String> = ["-d", "-D", "-m", "-M", "-u", "-c", "-C", "--delete", "--move", "--copy"]
    private static let readSimulatorCommands: Set<String> = ["list", "get_app_container", "listapps", "bootstatus", "terminate"]
    private static let readExecutables: Set<String> = ["du", "ps", "grep", "plutil", "pgrep"]

    static func classify(executable: String, arguments: [String]) -> CommandKind {
        let name = URL(fileURLWithPath: executable).lastPathComponent
        switch name {
        case "security": return .secret
        case "git": return classifyGit(arguments)
        case "xcrun": return classifyXcrun(arguments)
        case "simctl": return classifySimulator(arguments)
        case "xcodebuild": return arguments.contains("-showBuildSettings") ? .read : .action
        case "gh", "glab": return classifyHostingCLI(arguments)
        case "osascript": return arguments.contains { $0.contains("click") } ? .action : .read
        default: return readExecutables.contains(name) ? .read : .action
        }
    }

    private static func classifyGit(_ arguments: [String]) -> CommandKind {
        guard let index = gitSubcommandIndex(arguments) else { return .action }
        let subcommand = arguments[index]
        let rest = Array(arguments.dropFirst(index + 1))
        switch subcommand {
        case "branch":
            return rest.contains { writingBranchFlags.contains($0) } ? .action : .read
        case "worktree", "stash":
            return rest.first == "list" ? .read : .action
        case "remote":
            return rest.first == "show" || rest.first == "get-url" || rest.isEmpty || rest.first == "-v" ? .read : .action
        default:
            return readGitSubcommands.contains(subcommand) ? .read : .action
        }
    }

    private static func gitSubcommandIndex(_ arguments: [String]) -> Int? {
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if argument == "-C" || argument == "-c" {
                index += 2
            } else if argument.hasPrefix("-") {
                index += 1
            } else {
                return index
            }
        }
        return nil
    }

    private static func classifyXcrun(_ arguments: [String]) -> CommandKind {
        guard let first = arguments.first(where: { $0.hasPrefix("-") == false }) else { return .action }
        let rest = Array(arguments.drop { $0 != first }.dropFirst())
        return first == "simctl" ? classifySimulator(rest) : .action
    }

    private static func classifySimulator(_ arguments: [String]) -> CommandKind {
        guard let first = arguments.first else { return .action }
        if first == "spawn" {
            if arguments.contains("log"), arguments.contains("stream") {
                return .appLog
            }
            return arguments.contains("read") ? .read : .action
        }
        return readSimulatorCommands.contains(first) ? .read : .action
    }

    private static func classifyHostingCLI(_ arguments: [String]) -> CommandKind {
        if arguments.starts(with: ["auth", "token"]) {
            return .secret
        }
        if arguments.first == "api" {
            return .read
        }
        return arguments.count >= 2 && arguments[0] == "pr" && arguments[1] == "view" ? .read : .action
    }
}
