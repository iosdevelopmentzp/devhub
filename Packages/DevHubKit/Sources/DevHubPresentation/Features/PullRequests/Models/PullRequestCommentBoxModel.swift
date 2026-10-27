import Foundation
import DevHubUI

struct PullRequestCommentBoxModel: Equatable {
    var draft: String
    var placeholder: String
    var isBusy: Bool
    var canSend: Bool
    var canRequestChanges: Bool
    var requestChangesHint: String

    static let preview = PullRequestCommentBoxModel(
        draft: "",
        placeholder: "Comment on #12…",
        isBusy: false,
        canSend: false,
        canRequestChanges: true,
        requestChangesHint: "Send the comment as a review that asks for changes before #12 can merge"
    )
}
