import Foundation

package struct MergeRequestThread: Identifiable, Hashable, Sendable {
    package let id: String
    package let noteID: Int?
    package let author: String
    package let body: String
    package let filePath: String?
    package let line: Int?
    package let isOnOldLine: Bool
    package let replies: [MergeRequestNote]

    package init(id: String, noteID: Int?, author: String, body: String, filePath: String?, line: Int?, isOnOldLine: Bool, replies: [MergeRequestNote]) {
        self.id = id
        self.noteID = noteID
        self.author = author
        self.body = body
        self.filePath = filePath
        self.line = line
        self.isOnOldLine = isOnOldLine
        self.replies = replies
    }

    package var replyCount: Int {
        replies.count
    }
}
