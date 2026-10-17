import Foundation
import DevHubUI

enum PullRequestCalmStyleMapper {
    static let attentionTints: Set<Tint> = [.red, .indigo]

    static func calm(_ model: PullRequestRowModel) -> PullRequestRowModel {
        var calm = model
        calm.usesPlainTags = true
        calm.tags = model.tags.map(quiet)
        calm.labelTags = model.labelTags.map(quiet)
        if let ticket = model.ticket, model.title.contains(ticket.key) {
            calm.ticket = nil
        }
        return calm
    }

    static func quiet(_ tag: TagModel) -> TagModel {
        guard attentionTints.contains(tag.tint) == false else { return tag }
        var quiet = tag
        quiet.tint = .secondary
        return quiet
    }
}
