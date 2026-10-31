import Foundation
import DevHubDomain
import DevHubUI

struct InboxRowModel: Identifiable, Equatable {
    let id: String
    var icon: String
    var iconTint: Tint
    var iconHint: String
    var title: String
    var detail: String
    var dateText: String?
    var webURL: URL?
    var pullRequestIID: Int?
    var openHint: String?
    var doneHint: String
    var isBusy: Bool

    static let preview = InboxRowModel(
        id: "901",
        icon: "at",
        iconTint: .purple,
        iconHint: "Mention",
        title: "sam mentioned you in !12",
        detail: "ABC-123: Login screen · @alex can you check the retry path?",
        dateText: "25 min. ago",
        webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/12#note_901"),
        pullRequestIID: 12,
        openHint: "Open !12 in DevHub",
        doneHint: "Mark as done on GitLab",
        isBusy: false
    )
}
