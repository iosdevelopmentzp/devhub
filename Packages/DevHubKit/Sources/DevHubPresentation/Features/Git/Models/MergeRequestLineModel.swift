import Foundation
import DevHubDomain
import DevHubUI

struct MergeRequestLineModel: Equatable {
    enum Content: Equatable {
        case notConnected(loginCommand: String)
        case failure(String)
        case status(Status)
        case checking
    }

    struct Status: Equatable {
        var requestTag: TagModel?
        var requestIID: Int?
        var requestURL: URL?
        var linkText: String?
        var requestTags: [TagModel]
        var placeholder: String?
        var pipelineTag: TagModel?
        var pipelineURL: URL?
    }

    var content: Content
    var isLoading: Bool
    var canRefresh: Bool

    static let preview = MergeRequestLineModel(
        content: .status(
            Status(
                requestTag: TagModel(
                    "!1842 open",
                    tint: .blue,
                    systemImage: "arrow.triangle.pull",
                    hint: "ABC-2324: Paid call payment\nby alex into dev. Click to show it in the GitLab tab."
                ),
                requestIID: 1842,
                requestURL: nil,
                linkText: "!1842 ABC-2324: Paid call payment",
                requestTags: [TagModel("needs approval", tint: .orange, hint: "GitLab merge status: not_approved")],
                placeholder: nil,
                pipelineTag: TagModel(
                    "pipeline success",
                    tint: .green,
                    systemImage: "checkmark.circle.fill",
                    hint: "Latest pipeline on this branch, 5 min. ago. Click to open it."
                ),
                pipelineURL: nil
            )
        ),
        isLoading: false,
        canRefresh: true
    )
}
