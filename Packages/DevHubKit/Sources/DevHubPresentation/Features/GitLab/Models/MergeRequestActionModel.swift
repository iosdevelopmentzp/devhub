import Foundation
import DevHubUI

struct MergeRequestActionModel: Identifiable, Equatable {
    enum Kind: Hashable {
        case approve
        case unapprove
        case markReady
        case markDraft
        case rebase
        case retryPipeline
        case merge
        case mergeWhenPipelinePasses
        case cancelAutoMerge
        case cancelPipeline
    }

    let id: Kind
    var title: String
    var systemImage: String
    var hint: String
    var tint: Tint?

    static let preview = MergeRequestActionModel(id: .approve, title: "Approve", systemImage: "checkmark.seal", hint: "Approve this merge request as you", tint: .green)
}
