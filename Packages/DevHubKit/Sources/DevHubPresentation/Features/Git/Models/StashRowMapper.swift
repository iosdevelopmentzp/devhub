import Foundation
import DevHubDomain
import DevHubUI

enum StashRowMapper {

    static func model(for stash: GitStash, isBusy: Bool, expansion: CommitRowMapper.Expansion? = nil) -> StashRowModel {
        let reference = stash.reference
        return StashRowModel(
            id: stash.id,
            hash: stash.hash,
            reference: reference,
            message: stash.message.isEmpty ? "No message" : stash.message,
            branch: stash.branch,
            dateText: stash.date?.relativeDescription,
            dropMessage: "Drop \(reference)? Its changes are lost.",
            branchPlaceholder: "\(stash.branch ?? "stash")-stash",
            areActionsEnabled: isBusy == false,
            files: expansion.map { CommitRowMapper.files(for: stash.hash, $0) }
        )
    }
}
