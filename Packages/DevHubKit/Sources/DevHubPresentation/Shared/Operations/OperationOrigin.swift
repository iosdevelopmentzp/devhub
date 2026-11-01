import Foundation

struct OperationOrigin: Hashable {
    let key: String

    static let git = OperationOrigin(key: "git")
    static let changes = OperationOrigin(key: "changes")
    static let simulators = OperationOrigin(key: "simulators")
    static let messaging = OperationOrigin(key: "messaging")
    static let worktrees = OperationOrigin(key: "worktrees")
    static let pullRequests = OperationOrigin(key: "pullRequests")
    static let newPullRequest = OperationOrigin(key: "newPullRequest")
    static let disk = OperationOrigin(key: "disk")

    static func action(_ id: String) -> OperationOrigin {
        OperationOrigin(key: "action:" + id)
    }

    static func worktree(_ path: String) -> OperationOrigin {
        OperationOrigin(key: "worktree:" + path)
    }

    static func simulator(_ udid: String) -> OperationOrigin {
        OperationOrigin(key: "simulator:" + udid)
    }

    static func pullRequest(_ iid: Int) -> OperationOrigin {
        OperationOrigin(key: "pullRequest:\(iid)")
    }
}
