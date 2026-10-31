import Foundation

package struct ReviewThread: Identifiable, Hashable, Sendable {
    package let id: String
    package let noteID: Int?
    package let author: String
    package let body: String
    package let createdAt: Date?
    package let filePath: String?
    package let line: Int?
    package let isOnOldLine: Bool
    package let replies: [PullRequestNote]

    package init(id: String, noteID: Int?, author: String, body: String, createdAt: Date? = nil, filePath: String?, line: Int?, isOnOldLine: Bool, replies: [PullRequestNote]) {
        self.id = id
        self.noteID = noteID
        self.author = author
        self.body = body
        self.createdAt = createdAt
        self.filePath = filePath
        self.line = line
        self.isOnOldLine = isOnOldLine
        self.replies = replies
    }

    package var replyCount: Int {
        replies.count
    }
}
