import Foundation
import DevHubDomain
import DevHubUI

enum HiddenFileRowMapper {
    static let skipWorktreeHint = "skip-worktree: git keeps your local version and does not show its changes. A pull or a switch stops when the file changed upstream."
    static let assumeUnchangedHint = "assume-unchanged: git does not check the file for changes. It is a speed hint: a reset, a pull or a switch can drop it."

    static func model(
        for file: GitHiddenFile,
        checkoutPath: String,
        isExpanded: Bool,
        diff: GitDiff?,
        isBusy: Bool,
        syntaxColors: Bool
    ) -> HiddenFileRowModel {
        let fullPath = (checkoutPath as NSString).appendingPathComponent(file.path)
        let folderPath = (fullPath as NSString).deletingLastPathComponent
        let isDeleted = file.state == .deleted
        return HiddenFileRowModel(
            id: file.id,
            letter: letter(file.state),
            letterTint: tint(file.state),
            letterHint: hint(file.state),
            fileName: file.fileName,
            detail: file.folder,
            path: file.path,
            fullPath: fullPath,
            revealPath: isDeleted ? folderPath : fullPath,
            canOpen: isDeleted == false,
            flags: GitHiddenFlag.allCases.filter { file.flags.contains($0) }.map(flagTag),
            hasChanges: file.hasChanges,
            trackHint: file.hasChanges
                ? "Track again: git shows the changes of this file again"
                : "Track again: git checks this file again",
            discardMessage: "Discard the local changes of \(file.fileName) and track it again? They cannot be restored.",
            areActionsEnabled: isBusy == false,
            diff: isExpanded ? diffModel(for: file, diff: diff, syntaxColors: syntaxColors) : nil,
            diffText: isExpanded && file.hasChanges ? diffText(diff) : nil
        )
    }

    private static func diffModel(for file: GitHiddenFile, diff: GitDiff?, syntaxColors: Bool) -> DiffModel {
        guard file.hasChanges else {
            return .note("No hidden changes: the file is the same as in git.")
        }
        return DiffMapper.model(for: diff, language: DiffSyntaxMapper.language(forPath: file.path, syntaxColors: syntaxColors))
    }

    private static func diffText(_ diff: GitDiff?) -> String? {
        guard let diff, diff.isBinary == false, diff.lines.isEmpty == false else { return nil }
        return diff.lines.joined(separator: "\n")
    }

    private static func flagTag(_ flag: GitHiddenFlag) -> HiddenFileRowModel.FlagTag {
        switch flag {
        case .skipWorktree: HiddenFileRowModel.FlagTag(text: flag.name, hint: skipWorktreeHint)
        case .assumeUnchanged: HiddenFileRowModel.FlagTag(text: flag.name, hint: assumeUnchangedHint)
        }
    }

    private static func letter(_ state: GitHiddenFile.State) -> String {
        switch state {
        case .modified: "M"
        case .deleted: "D"
        case .unchanged: "="
        }
    }

    private static func tint(_ state: GitHiddenFile.State) -> Tint {
        switch state {
        case .modified: .orange
        case .deleted: .red
        case .unchanged: .gray
        }
    }

    private static func hint(_ state: GitHiddenFile.State) -> String {
        switch state {
        case .modified: "Changed on disk. git does not show the change"
        case .deleted: "Deleted on disk. git does not show the change"
        case .unchanged: "Same as in git"
        }
    }
}
