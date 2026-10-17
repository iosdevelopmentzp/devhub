import Foundation
import DevHubDomain
import DevHubUI

enum StashRowMapper {

    static func model(for stash: GitStash, isBusy: Bool) -> StashRowModel {
        let reference = "stash@{\(stash.index)}"
        return StashRowModel(
            id: stash.id,
            reference: reference,
            message: stash.message.isEmpty ? "No message" : stash.message,
            branch: stash.branch,
            dateText: stash.date?.relativeDescription,
            dropMessage: "Drop \(reference)? Its changes are lost.",
            areActionsEnabled: isBusy == false
        )
    }
}
