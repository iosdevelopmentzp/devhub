import Foundation

nonisolated struct GitStatus: Hashable, Sendable {
    var branch: String?
    var objectID: String?
    var upstream: String?
    var ahead: Int
    var behind: Int
    var changes: [GitChange]

    var isDetached: Bool { branch == nil }

    var shortHash: String {
        String((objectID ?? "").prefix(8))
    }

    var changeCount: Int { changes.count }

    var isClean: Bool { changes.isEmpty }

    static let empty = GitStatus(branch: nil, objectID: nil, upstream: nil, ahead: 0, behind: 0, changes: [])
}

nonisolated enum GitOperation: String, Hashable, Sendable {
    case rebase
    case merge
    case cherryPick

    var title: String {
        switch self {
        case .rebase: "Rebase"
        case .merge: "Merge"
        case .cherryPick: "Cherry-pick"
        }
    }
}

nonisolated struct BranchDistance: Hashable, Sendable {
    var ahead: Int
    var behind: Int

    static let zero = BranchDistance(ahead: 0, behind: 0)
}

nonisolated struct CheckoutDetails: Hashable, Sendable {
    var operation: GitOperation?
    var lastFetch: Date?
    var stashCount: Int
    var distance: BranchDistance?

    static let empty = CheckoutDetails(operation: nil, lastFetch: nil, stashCount: 0, distance: nil)
}

nonisolated struct GitCommit: Identifiable, Hashable, Sendable {
    let hash: String
    let author: String
    let date: Date
    let subject: String
    var isPushed: Bool

    var id: String { hash }

    var shortHash: String { String(hash.prefix(8)) }
}

nonisolated struct GitDiff: Hashable, Sendable {
    static let lineLimit = 4000

    var lines: [String]
    var isBinary: Bool
    var hiddenLineCount: Int

    static let binary = GitDiff(lines: [], isBinary: true, hiddenLineCount: 0)
    static let empty = GitDiff(lines: [], isBinary: false, hiddenLineCount: 0)

    init(lines: [String], isBinary: Bool, hiddenLineCount: Int) {
        self.lines = lines
        self.isBinary = isBinary
        self.hiddenLineCount = hiddenLineCount
    }

    init(text: String) {
        let all = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let trimmed = all.last == "" ? Array(all.dropLast()) : all
        isBinary = trimmed.contains { $0.hasPrefix("Binary files ") && $0.hasSuffix(" differ") } || trimmed.contains { $0.hasPrefix("GIT binary patch") }
        lines = Array(trimmed.prefix(Self.lineLimit))
        hiddenLineCount = max(0, trimmed.count - Self.lineLimit)
    }
}
