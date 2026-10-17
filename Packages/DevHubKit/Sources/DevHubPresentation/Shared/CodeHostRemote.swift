import Foundation
import DevHubDomain

@MainActor
final class CodeHostRemote: CodeHostLookup {
    private let git: any GitRepository
    private let worktrees: any WorktreeLookup
    private var cached: CodeHost?
    private var subscription: SubscriptionToken?

    init(git: any GitRepository, worktrees: any WorktreeLookup, events: AppEvents) {
        self.git = git
        self.worktrees = worktrees
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                cached = nil
            default:
                break
            }
        }
    }

    var remoteName: String {
        worktrees.gitSettings.remote
    }

    func codeHost() async throws -> CodeHost {
        if let cached { return cached }
        let settings = worktrees.gitSettings
        guard let url = await git.webURL(checkoutPath: worktrees.mainCheckoutPath, remote: settings.remote),
              let host = CodeHostPolicy.codeHost(webURL: url, kind: settings.hostKind, name: settings.hostName)
        else { throw PullRequestError.noCodeHost }
        cached = host
        return host
    }
}
