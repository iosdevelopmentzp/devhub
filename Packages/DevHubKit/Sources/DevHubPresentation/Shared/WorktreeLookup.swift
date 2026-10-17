import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol WorktreeLookup: AnyObject {
    var worktrees: [Worktree] { get }
    var mainWorktree: Worktree? { get }
    var mainCheckoutPath: String { get }
    var baseBranch: String { get }
    func worktree(atPath path: String) -> Worktree?
    func checkoutPath(forBranch name: String) -> String?
}
