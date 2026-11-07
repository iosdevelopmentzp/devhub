import Foundation
import DevHubDomain
import DevHubUI

struct CommitRowModel: Identifiable, Equatable {
    enum Files: Equatable {
        case loading
        case note(String)
        case loaded([CommitFileRowModel])
    }

    let id: GitCommit.ID
    var hash: String
    var shortHash: String
    var subject: String
    var refTags: [TagModel]
    var tags: [TagModel]
    var author: String
    var dateText: String?
    var webURL: URL?
    var files: Files?
    var containingTags: [TagModel]?

    var isExpanded: Bool {
        files != nil
    }

    static let preview = CommitRowModel(
        id: "a1b2c3d4e5f6",
        hash: "a1b2c3d4e5f6",
        shortHash: "a1b2c3d",
        subject: "ABC-2324: Paid call payment",
        refTags: [TagModel("HEAD", tint: .blue, systemImage: "location.fill"), TagModel("ABC-2324-paidCall", tint: .indigo, systemImage: "arrow.triangle.branch")],
        tags: [TagModel("not pushed", tint: .orange)],
        author: "alex",
        dateText: "1 hr. ago",
        webURL: URL(string: "https://gitlab.com/example/app/-/commit/a1b2c3d4e5f6"),
        files: .loaded([.preview]),
        containingTags: [TagModel("ABC-2324-paidCall", tint: .indigo, systemImage: "arrow.triangle.branch"), TagModel("origin/dev", tint: .teal, systemImage: "cloud")]
    )
}
