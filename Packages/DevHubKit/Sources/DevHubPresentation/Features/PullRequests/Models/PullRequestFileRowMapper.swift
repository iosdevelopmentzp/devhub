import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestFileRowMapper {

    static func model(for file: PullRequestFileDiff, review: PullRequestReviewState, threads: [PullRequestThreadRowModel]) -> PullRequestFileRowModel {
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
            diff: isExpanded ? diff(file) : nil,
            highlightedLineID: isExpanded ? highlightedLineID(file, focus: review.focus) : nil,
            threadCountText: fileThreads.isEmpty ? nil : "\(fileThreads.count)",
            diffThreads: isExpanded && review.showsThreadsInDiff ? diffThreads(fileThreads, in: file, open: review.openDiffThreads) : [:]
        )
    }

    static func diffThreads(_ threads: [PullRequestThreadRowModel], in file: PullRequestFileDiff, open: Set<PullRequestThread.ID>) -> [Int: [DiffThreadModel]] {
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
                    summary: summary(thread.body),
                    repliesText: thread.repliesText,
                    isOpen: open.contains(thread.id),
                    thread: row
                )
            )
        }
        return result
    }

    private static func summary(_ body: String) -> String {
        let firstLine = body.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        return firstLine.trimmingCharacters(in: .whitespaces)
    }

    private static func highlightedLineID(_ file: PullRequestFileDiff, focus: DiffFocus?) -> Int? {
        guard let focus, focus.path == file.path,
              let index = DiffLineLocator.index(ofLine: focus.line, isOld: focus.isOld, in: file.diff.lines) else { return nil }
        let headerEnd = file.diff.lines.firstIndex { $0.hasPrefix("@@") } ?? 0
        return index - headerEnd
    }

    private static func diff(_ file: PullRequestFileDiff) -> DiffModel {
        if file.isTooLarge {
            return .note("The diff is too large for GitLab to show. Open the merge request in GitLab.")
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
