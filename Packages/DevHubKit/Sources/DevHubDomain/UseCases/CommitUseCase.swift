import Foundation

package struct CommitUseCase: Sendable {
    package enum PushResult: Sendable {
        case skipped
        case pushed(branch: String)
        case failed(branch: String, error: any Error)
    }

    package let git: any GitRepository

    package func execute(
        message: String,
        amend: Bool,
        thenPush: Bool,
        branch: String?,
        upstream: String?,
        checkoutPath: String
    ) async throws -> PushResult {
        try await git.perform(.commit(message: message, amend: amend), in: checkoutPath)
        guard thenPush, let branch else { return .skipped }
        do {
            try await PushCurrentBranchUseCase(git: git).execute(branch: branch, upstream: upstream, checkoutPath: checkoutPath)
            return .pushed(branch: branch)
        } catch {
            return .failed(branch: branch, error: error)
        }
    }
}
