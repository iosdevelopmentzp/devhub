import Foundation

package struct PushCurrentBranchUseCase: Sendable {
    package let git: any GitRepository

    package func execute(branch: String, upstream: String?, checkoutPath: String) async throws {
        try await git.perform(.push(branch: branch, setUpstream: upstream == nil), in: checkoutPath)
    }
}
