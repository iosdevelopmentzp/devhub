import Foundation

nonisolated struct WorktreeInfo: Identifiable, Hashable, Sendable {
    var path: String
    var branch: String?
    var head: String
    var isMain: Bool
    var isLocked: Bool
    var isMissing: Bool
    var changeCount: Int
    var ahead: Int
    var behind: Int
    var hasUpstream: Bool
    var isMerged: Bool
    var isRemoteGone: Bool
    var lastCommitSubject: String?
    var lastCommitDate: Date?
    var needsBootstrap: Bool

    var id: String { path }

    var title: String {
        branch ?? "detached " + String(head.prefix(8))
    }

    var isDirty: Bool { changeCount > 0 }

    var isNotPushed: Bool {
        guard branch != nil else { return false }
        return hasUpstream == false || ahead > 0
    }

    var isFinished: Bool {
        isMain == false && isMissing == false && (isMerged || isRemoteGone)
    }

    var isRemovable: Bool {
        isFinished && isDirty == false && isLocked == false
    }

    var folderName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    static func sample(path: String, branch: String?, isMain: Bool = false) -> WorktreeInfo {
        WorktreeInfo(
            path: path,
            branch: branch,
            head: "0123456789abcdef",
            isMain: isMain,
            isLocked: false,
            isMissing: false,
            changeCount: 0,
            ahead: 0,
            behind: 0,
            hasUpstream: true,
            isMerged: false,
            isRemoteGone: false,
            lastCommitSubject: nil,
            lastCommitDate: nil,
            needsBootstrap: false
        )
    }
}

nonisolated struct DerivedDataEntry: Hashable, Sendable {
    var folders: [String]
    var bytes: Int64
}

nonisolated struct DerivedDataReport: Hashable, Sendable {
    var root: String
    var totalBytes: Int64
    var entries: [String: DerivedDataEntry]

    static let empty = DerivedDataReport(root: "", totalBytes: 0, entries: [:])
}

nonisolated struct WorktreeSections: Sendable {
    var main: WorktreeInfo?
    var inProgress: [WorktreeInfo]
    var finished: [WorktreeInfo]
    var missing: [WorktreeInfo]

    init(_ worktrees: [WorktreeInfo]) {
        main = worktrees.first { $0.isMain }
        let others = worktrees.filter { $0.isMain == false }
        missing = others.filter(\.isMissing)
        finished = others.filter(\.isFinished)
        inProgress = others.filter { $0.isMissing == false && $0.isFinished == false }
    }
}

nonisolated enum WorktreeCreation: Hashable, Sendable {
    case local(String)
    case remote(String)
    case new(String)

    var branch: String {
        switch self {
        case let .local(name), let .remote(name), let .new(name): name
        }
    }

    var summary: String {
        switch self {
        case let .local(name): "Check out \(name)"
        case let .remote(name): "Track origin/\(name)"
        case let .new(name): "New branch \(name)"
        }
    }
}

nonisolated struct WorktreeFailure: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
