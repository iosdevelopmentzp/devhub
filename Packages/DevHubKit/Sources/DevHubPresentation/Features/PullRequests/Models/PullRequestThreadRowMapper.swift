import Foundation
import DevHubDomain

enum PullRequestThreadRowMapper {

    static func model(for thread: PullRequestThread, diffs: [PullRequestFileDiff], webURL: URL?, isBusy: Bool) -> PullRequestThreadRowModel {
        let fullLocation = thread.filePath.map { path in thread.line.map { "\(path):\($0)" } ?? path }
        let shortLocation = thread.filePath.map { path in
            let name = (path as NSString).lastPathComponent
            return thread.line.map { "\(name):\($0)" } ?? name
        }
        return PullRequestThreadRowModel(
            id: thread.id,
            author: thread.author,
            location: shortLocation,
            locationHint: fullLocation,
            body: thread.body,
            repliesText: repliesText(thread.replyCount),
            replies: thread.replies.enumerated().map { PullRequestNoteModel(id: $0.offset, author: $0.element.author, body: $0.element.body) },
            filePath: thread.filePath,
            line: thread.line,
            isOnOldLine: thread.isOnOldLine,
            canShowInDiff: canShowInDiff(thread, diffs: diffs),
            noteURL: noteURL(thread, webURL: webURL),
            isBusy: isBusy
        )
    }

    private static func canShowInDiff(_ thread: PullRequestThread, diffs: [PullRequestFileDiff]) -> Bool {
        guard let path = thread.filePath, let line = thread.line, let file = diffs.first(where: { $0.path == path }) else { return false }
        return DiffLineLocator.index(ofLine: line, isOld: thread.isOnOldLine, in: file.diff.lines) != nil
    }

    private static func noteURL(_ thread: PullRequestThread, webURL: URL?) -> URL? {
        guard let webURL, let noteID = thread.noteID else { return nil }
        return URL(string: "\(webURL.absoluteString)#note_\(noteID)")
    }

    private static func repliesText(_ count: Int) -> String? {
        switch count {
        case 0: nil
        case 1: "1 reply"
        default: "\(count) replies"
        }
    }
}
