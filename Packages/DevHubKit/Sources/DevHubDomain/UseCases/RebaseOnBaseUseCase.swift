import Foundation

package struct RebaseOnBaseUseCase: Sendable {
    package let git: any GitRepository

    package func execute(baseName: String, baseRef: String, checkoutPath: String) async throws {
        try await git.perform(.fetchRef(baseName), in: checkoutPath)
        try await git.perform(.rebase(onto: baseRef, autostash: true), in: checkoutPath)
    }
}
