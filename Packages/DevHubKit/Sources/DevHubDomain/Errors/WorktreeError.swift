import Foundation

package enum WorktreeError: LocalizedError, Sendable {
    case notARepository(String)
    case command(String)
    case invalidBranchName

    package var errorDescription: String? {
        switch self {
        case .notARepository(let path):
            "\(path) is not a git repository."
        case .command(let message):
            message
        case .invalidBranchName:
            "Branch name is not valid."
        }
    }
}
