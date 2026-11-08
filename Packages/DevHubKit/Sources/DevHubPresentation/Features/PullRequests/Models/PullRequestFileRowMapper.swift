import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestFileRowMapper {

    static func model(for original: PullRequestFileDiff, review: PullRequestReviewState, threads: [ReviewThreadRowModel], layout standard: DiffLayout, words: CodeHostWords) -> PullRequestFileRowModel {
        let isFull = review.fullFiles.contains(original.id)
        let layout = review.fileLayouts[original.id] ?? standard
        let file = isFull ? expanded(original, review: review) : original
        let folder = (file.path as NSString).deletingLastPathComponent
        let isExpanded = review.expandedFiles.contains(file.id)
        let fileThreads = threads.filter { $0.filePath == file.path }
        return PullRequestFileRowModel(
            id: file.id,
            letter: letter(file.kind),
            letterTint: tint(file.kind),
            letterHint: hint(file),
            fileName: (file.path as NSString).lastPathComponent,
            detail: file.kind == .renamed ? "from \(file.oldPath)" : folder,
            path: file.path,
            additionsText: "+\(file.additions)",
            deletionsText: "−\(file.deletions)",
            isExpanded: isExpanded,
            isViewed: review.viewedFiles.contains(file.id),
            diff: isExpanded ? diff(file, words: words) : nil,
            highlightedLineID: isExpanded ? highlightedLineID(file, focus: review.focus) : nil,
            isFocused: review.focus?.path == file.path,
            threadCountText: fileThreads.isEmpty ? nil : "\(fileThreads.count)",
            diffThreads: isExpanded && review.showsThreadsInDiff ? diffThreads(fileThreads, in: file, open: review.openDiffThreads) : [:],
            oldPath: file.oldPath,
            lineComposer: isExpanded ? lineComposer(review: review, path: file.path) : nil,
            canOpenOnWeb: file.kind != .deleted,
            isFull: isFull,
            fullHint: fullHint(original, isFull: isFull, words: words),
            layout: layout,
            layoutHint: layoutHint(original, layout: layout),
            isFullLoading: isFull && review.fileContents[original.id] == nil
        )
    }

    static func hiding(_ model: PullRequestFileRowModel, isHidden: Bool, isChosen: Bool, group: String? = nil) -> PullRequestFileRowModel {
        var hidden = model
        hidden.canHide = isHidden == false
        hidden.canUnhide = isChosen
        hidden.hiddenTag = isHidden ? TagModel("hidden", tint: .secondary, systemImage: "eye.slash", hint: hiddenHint(isChosen: isChosen, group: group)) : nil
        return hidden
    }

    private static func hiddenHint(isChosen: Bool, group: String?) -> String {
        if isChosen {
            return "You hid this file in the requests of this project. The eye button shows it again."
        }
        if let group {
            return "This file is in the group \(group), hidden by its chip above the list (git.pullRequests.fileGroups in project.json)"
        }
        return "This file matches git.pullRequests.hiddenFiles in project.json"
    }

    static func expanded(_ file: PullRequestFileDiff, review: PullRequestReviewState) -> PullRequestFileDiff {
        guard let lines = review.fileContents[file.id], let diff = DiffContextExpansion.expanded(file.diff, fileLines: lines) else { return file }
        return PullRequestFileDiff(oldPath: file.oldPath, path: file.path, kind: file.kind, additions: file.additions, deletions: file.deletions, diff: diff, isTooLarge: file.isTooLarge)
    }

    private static func fullHint(_ file: PullRequestFileDiff, isFull: Bool, words: CodeHostWords) -> String? {
        guard file.kind == .modified || file.kind == .renamed, file.isTooLarge == false, file.diff.isBinary == false, file.diff.droppedLines == 0 else { return nil }
        return isFull
            ? "Show only the changed parts"
            : "Show the whole file with the changes in place. DevHub reads the file at the last commit of the \(words.request) from \(words.name)."
    }

    private static func layoutHint(_ file: PullRequestFileDiff, layout: DiffLayout) -> String? {
        guard file.kind == .modified || file.kind == .renamed, file.isTooLarge == false, file.diff.isBinary == false else { return nil }
        return layout == .sideBySide
            ? "Show this file unified: removed and added lines in one column. The other files keep their layout."
            : "Show this file side by side: the file before the change on the left, after it on the right. The other files keep their layout."
    }

    static func lineComposer(review: PullRequestReviewState, path: String) -> LineComposerModel? {
        guard let draft = review.lineComment, draft.path == path else { return nil }
        let line = draft.newLine ?? draft.oldLine ?? 0
        return LineComposerModel(
            lineID: draft.lineID,
            text: draft.text,
            placeholder: draft.newLine == nil ? "Comment on removed line \(line)…" : "Comment on line \(line)…",
            isBusy: review.isLineCommentBusy,
            canSend: review.isLineCommentBusy == false && draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        )
    }

    static func diffThreads(_ threads: [ReviewThreadRowModel], in file: PullRequestFileDiff, open: Set<ReviewThread.ID>) -> [Int: [DiffThreadModel]] {
        guard file.isTooLarge == false else { return [:] }
        let headerEnd = file.diff.lines.firstIndex { $0.hasPrefix("@@") } ?? 0
        var result: [Int: [DiffThreadModel]] = [:]
        for thread in threads {
            guard let line = thread.line,
                  let index = DiffLineLocator.index(ofLine: line, isOld: thread.isOnOldLine, in: file.diff.lines) else { continue }
            var row = thread
            row.canShowInDiff = false
            result[index - headerEnd, default: []].append(
                DiffThreadModel(
                    id: thread.id,
                    author: thread.author,
                    summary: CommentText.firstLine(String(thread.body.characters)),
                    repliesText: thread.repliesText,
                    isOpen: open.contains(thread.id),
                    thread: row
                )
            )
        }
        return result
    }

    private static func highlightedLineID(_ file: PullRequestFileDiff, focus: DiffFocus?) -> Int? {
        guard let focus, focus.path == file.path,
              let index = DiffLineLocator.index(ofLine: focus.line, isOld: focus.isOld, in: file.diff.lines) else { return nil }
        let headerEnd = file.diff.lines.firstIndex { $0.hasPrefix("@@") } ?? 0
        return index - headerEnd
    }

    private static func diff(_ file: PullRequestFileDiff, words: CodeHostWords) -> DiffModel {
        if file.isTooLarge {
            return .note("The diff is too large for \(words.name) to show. Open the \(words.request) in \(words.name).")
        }
        return DiffMapper.model(for: file.diff)
    }

    private static func letter(_ kind: PullRequestFileDiff.Kind) -> String {
        switch kind {
        case .added: "A"
        case .deleted: "D"
        case .renamed: "R"
        case .modified: "M"
        }
    }

    private static func tint(_ kind: PullRequestFileDiff.Kind) -> Tint {
        switch kind {
        case .added: .green
        case .deleted: .red
        case .renamed: .blue
        case .modified: .orange
        }
    }

    private static func hint(_ file: PullRequestFileDiff) -> String {
        switch file.kind {
        case .added: "Added"
        case .deleted: "Deleted"
        case .renamed: "Renamed from \(file.oldPath)"
        case .modified: "Modified"
        }
    }
}
