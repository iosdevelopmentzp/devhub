import Foundation
import DevHubDomain
import DevHubUI

struct BranchMergeRequestModel: Equatable {
    var iid: Int
    var tag: TagModel
    var pipelineTag: TagModel?
    var pipelineURL: URL?
    var statusTags: [TagModel]
    var webURL: URL?
    var linkText: String

    static let preview = BranchMergeRequestModel(
        iid: 1842,
        tag: TagModel("!1842", tint: .blue, systemImage: "arrow.triangle.pull", hint: "Open merge request into dev: ABC-2324: Paid call payment. Click to show it in the GitLab tab."),
        pipelineTag: .icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed. Click to open it."),
        pipelineURL: nil,
        statusTags: [TagModel("approved", tint: .green, systemImage: "checkmark.seal.fill", hint: "Approved by kim")],
        webURL: nil,
        linkText: "!1842 ABC-2324: Paid call payment"
    )
}
