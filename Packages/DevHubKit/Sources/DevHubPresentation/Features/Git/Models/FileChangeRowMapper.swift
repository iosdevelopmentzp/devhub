import Foundation
import DevHubDomain
import DevHubUI

enum FileChangeRowMapper {

    static func model(
        for change: GitFileChange,
        checkoutPath: String,
        isExpanded: Bool,
        diff: GitDiff?,
        isBusy: Bool,
        syntaxColors: Bool
    ) -> FileChangeRowModel {
        let fullPath = (checkoutPath as NSString).appendingPathComponent(change.path)
        let isStaged = change.area == .staged
        let isUntracked = change.area == .untracked
        let folderPath = (fullPath as NSString).deletingLastPathComponent
        let isDeleted = change.kind == .deleted
        return FileChangeRowModel(
            id: change.id,
            letter: String(change.kind.letter),
            letterTint: tint(change.kind),
            letterHint: hint(change.kind),
            fileName: change.fileName,
            detail: change.originalPath.map { "\($0) →" } ?? change.folder,
            path: change.path,
            fullPath: fullPath,
            folderPath: folderPath,
            revealPath: isDeleted ? folderPath : fullPath,
            canOpen: isDeleted == false,
            canHide: change.area == .unstaged && change.kind == .modified,
            isStaged: isStaged,
            stageIcon: isStaged ? "minus.circle" : "plus.circle",
            stageHint: stageHint(change.area),
            discardHint: isUntracked ? "Delete this new file" : "Discard the changes in this file",
            discardMessage: isUntracked
                ? "Delete \(change.fileName)? It was never committed, git cannot bring it back."
                : "Discard the changes in \(change.fileName)? They cannot be restored.",
            discardTitle: isUntracked ? "Delete" : "Discard",
            areActionsEnabled: isBusy == false,
            diff: isExpanded ? DiffMapper.model(for: diff, language: DiffSyntaxMapper.language(forPath: change.path, syntaxColors: syntaxColors)) : nil,
            diffText: isExpanded ? diffText(diff) : nil
        )
    }

    private static func diffText(_ diff: GitDiff?) -> String? {
        guard let diff, diff.isBinary == false, diff.lines.isEmpty == false else { return nil }
        return diff.lines.joined(separator: "\n")
    }

    private static func stageHint(_ area: GitFileChange.Area) -> String {
        switch area {
        case .staged: "Unstage: keep the change, leave it out of the next commit"
        case .conflicted: "Mark as resolved: stage the file"
        case .unstaged, .untracked: "Stage: include in the next commit"
        }
    }

    static func tint(_ kind: GitChangeKind) -> Tint {
        switch kind {
        case .added, .untracked: .green
        case .deleted: .red
        case .renamed, .copied: .blue
        case .conflicted: .purple
        case .modified, .typeChanged, .other: .orange
        }
    }

    static func hint(_ kind: GitChangeKind) -> String {
        switch kind {
        case .added: "Added"
        case .untracked: "New file, not tracked by git yet"
        case .deleted: "Deleted"
        case .renamed: "Renamed"
        case .copied: "Copied"
        case .conflicted: "Conflict: fix the file, then stage it"
        case .typeChanged: "File type changed"
        case .modified, .other: "Modified"
        }
    }
}
