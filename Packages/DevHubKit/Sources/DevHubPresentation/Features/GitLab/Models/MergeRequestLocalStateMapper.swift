import Foundation
import DevHubDomain
import DevHubUI

enum MergeRequestLocalStateMapper {

    static func state(for branch: String, currentBranch: String?, localBranches: Set<String>, checkoutPath: String?, mainCheckoutPath: String) -> MergeRequestLocalState {
        if branch == currentBranch || checkoutPath == mainCheckoutPath { return .current }
        if let checkoutPath { return .worktree(path: checkoutPath) }
        return localBranches.contains(branch) ? .local : .none
    }

    static func state(for branch: String, checkout: any CheckoutContext, worktrees: any WorktreeLookup) -> MergeRequestLocalState {
        state(
            for: branch,
            currentBranch: checkout.currentBranch,
            localBranches: checkout.localBranchNames,
            checkoutPath: worktrees.checkoutPath(forBranch: branch),
            mainCheckoutPath: worktrees.mainCheckoutPath
        )
    }

    static func tag(for state: MergeRequestLocalState) -> TagModel? {
        switch state {
        case .current:
            TagModel("current", tint: .teal, systemImage: "checkmark.circle", hint: "The source branch is checked out in the main checkout")
        case .worktree(let path):
            TagModel("worktree", tint: .teal, systemImage: "folder", hint: "The source branch has a worktree: \(ProjectPath(path).abbreviated)")
        case .local:
            TagModel("local", tint: .teal, systemImage: "laptopcomputer", hint: "The source branch exists on this Mac")
        case .none:
            nil
        }
    }
}
