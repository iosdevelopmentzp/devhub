import Foundation

package struct PullRequestLineComment: Hashable, Sendable {
    package let path: String
    package let oldPath: String
    package let newLine: Int?
    package let oldLine: Int?
    package let body: String
    package let headSHA: String?

    package init(path: String, oldPath: String, newLine: Int?, oldLine: Int?, body: String, headSHA: String?) {
        self.path = path
        self.oldPath = oldPath
        self.newLine = newLine
        self.oldLine = oldLine
        self.body = body
        self.headSHA = headSHA
    }
}
