import Foundation
import DevHubDomain

enum NotificationTargetCodec {
    private enum Keys {
        static let target = "target"
        static let iid = "iid"
        static let path = "path"
    }

    static func userInfo(for target: ActivityTarget?) -> [String: String] {
        switch target {
        case nil: [:]
        case .pullRequest(let iid): [Keys.target: "pullRequest", Keys.iid: String(iid)]
        case .reviewQueue: [Keys.target: "reviewQueue"]
        case .worktree(let path): [Keys.target: "worktree", Keys.path: path]
        case .build: [Keys.target: "build"]
        case .inbox: [Keys.target: "inbox"]
        case .utilities: [Keys.target: "utilities"]
        }
    }

    static func target(from userInfo: [AnyHashable: Any]) -> ActivityTarget? {
        switch userInfo[Keys.target] as? String {
        case "pullRequest":
            guard let text = userInfo[Keys.iid] as? String, let iid = Int(text) else { return nil }
            return .pullRequest(iid: iid)
        case "reviewQueue":
            return .reviewQueue
        case "worktree":
            guard let path = userInfo[Keys.path] as? String else { return nil }
            return .worktree(path: path)
        case "build":
            return .build
        case "inbox":
            return .inbox
        case "utilities":
            return .utilities
        default:
            return nil
        }
    }
}
