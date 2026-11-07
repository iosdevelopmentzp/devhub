import Foundation

struct UpdateCommitRowModel: Identifiable, Equatable {
    let id: String
    var hash: String
    var subject: String

    static let preview = UpdateCommitRowModel(id: "a1b2c3d", hash: "a1b2c3d", subject: "feat(git): stash files and diffs")
}
