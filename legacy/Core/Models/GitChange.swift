import Foundation

nonisolated struct GitChange: Identifiable, Hashable, Sendable {
    enum Group: Int, Hashable, Sendable, CaseIterable {
        case conflict
        case staged
        case unstaged
        case untracked

        var title: String {
            switch self {
            case .conflict: "Conflicts"
            case .staged: "Staged"
            case .unstaged: "Changes"
            case .untracked: "New"
            }
        }
    }

    let path: String
    let originalPath: String?
    let index: Character
    let worktree: Character

    var id: String { path }

    var isConflict: Bool { index == "u" }

    var isUntracked: Bool { index == "?" }

    var hasStagedChange: Bool {
        isConflict == false && isUntracked == false && index != "."
    }

    var hasUnstagedChange: Bool {
        isConflict == false && isUntracked == false && worktree != "."
    }

    var groups: [Group] {
        if isConflict { return [.conflict] }
        if isUntracked { return [.untracked] }
        var result: [Group] = []
        if hasStagedChange { result.append(.staged) }
        if hasUnstagedChange { result.append(.unstaged) }
        return result
    }

    func letter(in group: Group) -> Character {
        switch group {
        case .conflict: "!"
        case .staged: index
        case .unstaged: worktree
        case .untracked: "?"
        }
    }

    var fileName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var folder: String {
        let parent = (path as NSString).deletingLastPathComponent
        return parent
    }
}

nonisolated enum GitChangeLetter {
    static func title(_ letter: Character) -> String {
        switch letter {
        case "M": "Modified"
        case "A": "Added"
        case "D": "Deleted"
        case "R": "Renamed"
        case "C": "Copied"
        case "T": "Type changed"
        case "?": "New file"
        case "!": "Conflict"
        default: "Changed"
        }
    }
}
