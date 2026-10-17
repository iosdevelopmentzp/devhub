import Foundation
import DevHubDomain

extension GitStore {
    var stashes: [GitStash] {
        state?.stashes ?? []
    }

    func stash(message: String) {
        run("Stash", .stashPush(message: message, includeUntracked: true))
    }

    func popStash() {
        run("Stash pop", .stashPop(index: nil))
    }

    func apply(_ stash: GitStash) {
        run("Apply stash@{\(stash.index)}", .stashApply(index: stash.index))
    }

    func pop(_ stash: GitStash) {
        run("Pop stash@{\(stash.index)}", .stashPop(index: stash.index))
    }

    func drop(_ stash: GitStash) {
        run("Drop stash@{\(stash.index)}", .stashDrop(index: stash.index))
    }
}
