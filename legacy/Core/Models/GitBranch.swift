import Foundation

nonisolated struct GitBranch: Identifiable, Hashable, Sendable {
    let name: String
    var upstream: String?
    var ahead: Int
    var behind: Int
    var isUpstreamGone: Bool
    var commitDate: Date?
    var worktreePath: String?
    var subject: String
    var lastVisit: Date?
    var isMerged: Bool

    var id: String { name }

    var hasUpstream: Bool { upstream != nil }

    var isLocalOnly: Bool { upstream == nil }

    var isPushedTwin: Bool { upstream == "origin/" + name }

    var countsAsMerged: Bool { isMerged && isPushedTwin && ahead == 0 }

    var isFinished: Bool { countsAsMerged || isUpstreamGone }

    var sortDate: Date { lastVisit ?? commitDate ?? .distantPast }
}

nonisolated struct RemoteBranch: Identifiable, Hashable, Sendable {
    let name: String
    let author: String
    let date: Date
    let subject: String

    var id: String { name }

    var fullName: String { "origin/" + name }
}

nonisolated struct BranchSnapshot: Hashable, Sendable {
    var local: [GitBranch]
    var remote: [RemoteBranch]

    static let empty = BranchSnapshot(local: [], remote: [])

    func local(named name: String) -> GitBranch? {
        local.first { $0.name == name }
    }

    func hasLocal(_ name: String) -> Bool {
        local(named: name) != nil
    }

    func hasRemote(_ name: String) -> Bool {
        remote.contains { $0.name == name }
    }
}
