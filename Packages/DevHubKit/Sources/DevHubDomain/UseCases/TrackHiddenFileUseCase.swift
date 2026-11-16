import Foundation

package struct TrackHiddenFileUseCase: Sendable {
    package let git: any GitRepository

    package init(git: any GitRepository) {
        self.git = git
    }

    package func execute(_ file: GitHiddenFile, mode: GitTrackMode, checkoutPath: String) async throws {
        try await git.perform(.unhide(path: file.path), in: checkoutPath)
        guard file.hasChanges else { return }
        switch mode {
        case .keepChanges:
            return
        case .stashChanges:
            try await git.perform(.stashPath(path: file.path, message: Self.stashMessage(for: file)), in: checkoutPath)
        case .discardChanges:
            try await git.perform(.restore(path: file.path), in: checkoutPath)
        }
    }

    package static func stashMessage(for file: GitHiddenFile) -> String {
        "Hidden changes of \(file.path)"
    }
}
