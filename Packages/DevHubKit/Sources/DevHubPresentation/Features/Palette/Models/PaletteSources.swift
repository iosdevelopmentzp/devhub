import Foundation
import DevHubDomain
import DevHubUI

struct PaletteSources {
    var tabs: [TabItem]
    var actions: [CatalogAction]
    var simulators: [Simulator]
    var targetID: Simulator.ID?
    var branches: [String]
    var currentBranch: String?
    var worktrees: [Worktree]
    var pullRequests: [PullRequestSummary]
    var sessions: [AISession]
    var requestNumber: (Int) -> String
}
