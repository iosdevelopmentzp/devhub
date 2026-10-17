import Foundation

package struct GitSnapshot: Hashable, Sendable {
    package var branch: String?
    package var head: String
    package var upstream: String?
    package var ahead: Int
    package var behind: Int
    package var changedFiles: Int
    package var stashCount: Int
    package var operation: String?
    package var baseBranch: String
    package var aheadOfBase: Int
    package var behindBase: Int
    package var lastFetch: Date?
    package var webURL: URL?

    package init(
        branch: String?,
        head: String,
        upstream: String?,
        ahead: Int,
        behind: Int,
        changedFiles: Int,
        stashCount: Int,
        operation: String?,
        baseBranch: String,
        aheadOfBase: Int,
        behindBase: Int,
        lastFetch: Date?,
        webURL: URL?
    ) {
        self.branch = branch
        self.head = head
        self.upstream = upstream
        self.ahead = ahead
        self.behind = behind
        self.changedFiles = changedFiles
        self.stashCount = stashCount
        self.operation = operation
        self.baseBranch = baseBranch
        self.aheadOfBase = aheadOfBase
        self.behindBase = behindBase
        self.lastFetch = lastFetch
        self.webURL = webURL
    }
}
