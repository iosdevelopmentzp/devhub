import Foundation

package struct CreatePullRequestUseCase: Sendable {
    package enum PushPlan: Hashable, Sendable {
        case none
        case push(setUpstream: Bool)
    }

    package let git: any GitRepository
    package let codeHost: any CodeHostRepository

    package static func pushPlan(upstream: String?, ahead: Int, isCurrent: Bool) -> PushPlan {
        guard upstream != nil else { return .push(setUpstream: true) }
        guard ahead > 0 else { return .none }
        return .push(setUpstream: isCurrent == false)
    }

    package func execute(_ request: NewPullRequest, push: PushPlan, remote: String, checkoutPath: String, repository: CodeHost) async throws -> PullRequestSummary {
        if case .push(let setUpstream) = push {
            try await git.perform(.push(branch: request.sourceBranch, setUpstream: setUpstream, remote: remote), in: checkoutPath)
        }
        return try await codeHost.create(request, repository: repository)
    }
}
