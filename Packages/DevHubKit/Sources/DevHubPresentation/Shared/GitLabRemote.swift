import Foundation
import DevHubDomain

@MainActor
final class GitLabRemote: GitLabRemoteLookup {
    private let git: any GitRepository
    private let worktrees: any WorktreeLookup
    private var cached: URL?
    private var subscription: SubscriptionToken?

    init(git: any GitRepository, worktrees: any WorktreeLookup, events: AppEvents) {
        self.git = git
        self.worktrees = worktrees
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            cached = nil
        }
    }

    func gitLabURL() async throws -> URL {
        if let cached { return cached }
        guard let url = await git.webURL(checkoutPath: worktrees.mainCheckoutPath) else { throw MergeRequestError.notGitLab }
        cached = url
        return url
    }
}
