import Foundation

package enum BuildSourceError: LocalizedError, Sendable {
    case worktreeNotCreated(String)
    case creationFailed(branch: String, message: String)
    case bootstrapFailed(worktreeName: String, path: String, createdWorktree: Bool, message: String)

    package var errorDescription: String? {
        switch self {
        case .worktreeNotCreated(let branch), .creationFailed(let branch, _):
            "Could not create a worktree for \(branch). See the Output panel."
        case .bootstrapFailed(_, _, _, let message):
            message
        }
    }
}
