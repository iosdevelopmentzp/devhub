import Foundation
import DevHubDomain

struct LineCommentDraft: Equatable {
    let requestID: PullRequestSummary.ID
    let path: String
    let oldPath: String
    let lineID: Int
    let newLine: Int?
    let oldLine: Int?
    var text: String
}
