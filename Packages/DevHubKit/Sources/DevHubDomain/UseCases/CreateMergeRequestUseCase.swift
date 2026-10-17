import Foundation

package struct CreateMergeRequestUseCase: Sendable {
    package enum PushPlan: Hashable, Sendable {
        case none
        case push(setUpstream: Bool)
    }

    package let git: any GitRepository
    package let mergeRequests: any MergeRequestRepository

    package static func pushPlan(upstream: String?, ahead: Int, isCurrent: Bool) -> PushPlan {
        guard upstream != nil else { return .push(setUpstream: true) }
        guard ahead > 0 else { return .none }
        return .push(setUpstream: isCurrent == false)
    }

    package func execute(_ request: NewMergeRequest, push: PushPlan, checkoutPath: String, repository: URL) async throws -> MergeRequestSummary {
        if case .push(let setUpstream) = push {
            try await git.perform(.push(branch: request.sourceBranch, setUpstream: setUpstream), in: checkoutPath)
        }
        return try await mergeRequests.create(request, repository: repository)
    }
}
