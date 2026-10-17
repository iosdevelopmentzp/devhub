import Foundation

package struct GitCommit: Identifiable, Hashable, Sendable {
    package var id: String { hash }
    package var hash: String
    package var shortHash: String
    package var author: String
    package var date: Date?
    package var subject: String
    package var isPushed: Bool
    package var refs: [GitCommitRef]
    package var isMerge: Bool

    package init(hash: String, shortHash: String, author: String, date: Date?, subject: String, isPushed: Bool, refs: [GitCommitRef] = [], isMerge: Bool = false) {
        self.hash = hash
        self.shortHash = shortHash
        self.author = author
        self.date = date
        self.subject = subject
        self.isPushed = isPushed
        self.refs = refs
        self.isMerge = isMerge
    }
}
