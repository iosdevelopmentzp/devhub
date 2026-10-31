import Foundation
import DevHubUI

struct PullRequestReviewLineModel: Identifiable, Equatable {
    let id: String
    var title: String
    var tags: [TagModel]

    static let preview = PullRequestReviewLineModel(
        id: "approved",
        title: "Approved by",
        tags: [TagModel("robin", tint: .green, systemImage: "checkmark.seal.fill", hint: "robin approved this merge request")]
    )
}
