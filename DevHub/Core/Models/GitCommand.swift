import Foundation

nonisolated enum GitCommand: Hashable, Sendable {
    case fetch(prune: Bool)
    case pull
    case push(upstreamBranch: String?)
    case forcePush
    case rebase(onto: String)
    case updateBranch(String)
    case stash
    case popStash
    case switchBranch(String)
    case trackRemote(String)
    case stage([String])
    case stageAll
    case unstage([String])
    case unstageAll
    case restore(String)
    case restoreStaged(String)
    case removeAdded(String)
    case cleanFile(String)
    case commit(message: String, amend: Bool)
    case deleteBranch(String, force: Bool)
    case continueOperation(GitOperation)
    case abortOperation(GitOperation)
    case worktreeAdd(WorktreeCreation, path: String, base: String)
    case worktreeRemove(String, force: Bool)
    case worktreePrune
    case checkRefFormat(String)
    case verifyRef(String)

    var arguments: [String] {
        switch self {
        case let .fetch(prune): prune ? ["fetch", "--prune", "origin"] : ["fetch", "origin"]
        case .pull: ["pull", "--ff-only"]
        case let .push(upstreamBranch): upstreamBranch.map { ["push", "-u", "origin", $0] } ?? ["push"]
        case .forcePush: ["push", "--force-with-lease"]
        case let .rebase(base): ["rebase", "--autostash", base]
        case let .updateBranch(name): ["fetch", "origin", "\(name):\(name)"]
        case .stash: ["stash", "push", "--include-untracked"]
        case .popStash: ["stash", "pop"]
        case let .switchBranch(name): ["switch", name]
        case let .trackRemote(name): ["switch", "--track", "origin/\(name)"]
        case let .stage(paths): ["add", "--"] + paths
        case .stageAll: ["add", "-A"]
        case let .unstage(paths): ["restore", "--staged", "--"] + paths
        case .unstageAll: ["restore", "--staged", "."]
        case let .restore(path): ["restore", "--", path]
        case let .restoreStaged(path): ["restore", "--source=HEAD", "--staged", "--worktree", "--", path]
        case let .removeAdded(path): ["rm", "-f", "--", path]
        case let .cleanFile(path): ["clean", "-f", "--", path]
        case let .commit(message, amend): commitArguments(message: message, amend: amend)
        case let .deleteBranch(name, force): ["branch", force ? "-D" : "-d", name]
        case let .continueOperation(operation): continueArguments(operation)
        case let .abortOperation(operation): [operation.commandName, "--abort"]
        case let .worktreeAdd(creation, path, base): worktreeAddArguments(creation, path: path, base: base)
        case let .worktreeRemove(path, force): force ? ["worktree", "remove", "--force", "--force", path] : ["worktree", "remove", path]
        case .worktreePrune: ["worktree", "prune"]
        case let .checkRefFormat(name): ["check-ref-format", "--branch", name]
        case let .verifyRef(reference): ["show-ref", "--verify", "--quiet", reference]
        }
    }

    var environment: [String: String] {
        switch self {
        case .continueOperation: ["GIT_EDITOR": "true"]
        default: [:]
        }
    }

    var title: String {
        switch self {
        case .fetch: "Fetch"
        case .pull: "Pull"
        case .push: "Push"
        case .forcePush: "Force push"
        case .rebase: "Rebase"
        case let .updateBranch(name): "Update \(name)"
        case .stash: "Stash"
        case .popStash: "Pop stash"
        case let .switchBranch(name): "Switch to \(name)"
        case let .trackRemote(name): "Check out \(name)"
        case .stage, .stageAll: "Stage"
        case .unstage, .unstageAll: "Unstage"
        case .restore, .restoreStaged, .removeAdded, .cleanFile: "Discard"
        case let .commit(_, amend): amend ? "Amend commit" : "Commit"
        case let .deleteBranch(name, _): "Delete branch \(name)"
        case let .continueOperation(operation): "Continue \(operation.title.lowercased())"
        case let .abortOperation(operation): "Abort \(operation.title.lowercased())"
        case let .worktreeAdd(creation, _, _): "Create worktree for \(creation.branch)"
        case .worktreeRemove: "Delete worktree"
        case .worktreePrune: "Prune worktrees"
        case .checkRefFormat, .verifyRef: "Check branch name"
        }
    }

    private func commitArguments(message: String, amend: Bool) -> [String] {
        var arguments = ["commit"]
        if amend {
            arguments.append("--amend")
        }
        if message.isEmpty, amend {
            arguments.append("--no-edit")
        } else {
            arguments += ["-m", message]
        }
        return arguments
    }

    private func continueArguments(_ operation: GitOperation) -> [String] {
        [operation.commandName, "--continue"]
    }

    private func worktreeAddArguments(_ creation: WorktreeCreation, path: String, base: String) -> [String] {
        switch creation {
        case let .local(name): ["worktree", "add", path, name]
        case let .remote(name): ["worktree", "add", "--track", "-b", name, path, "origin/\(name)"]
        case let .new(name): ["worktree", "add", "--no-track", "-b", name, path, base]
        }
    }
}

nonisolated extension GitOperation {
    var commandName: String {
        switch self {
        case .rebase: "rebase"
        case .merge: "merge"
        case .cherryPick: "cherry-pick"
        }
    }
}
