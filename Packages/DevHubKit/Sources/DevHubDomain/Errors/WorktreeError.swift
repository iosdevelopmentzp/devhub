import Foundation

package enum WorktreeError: LocalizedError, Sendable {
    case notARepository(String)
    case command(String)
    case invalidBranchName
    case projectFolderNotIgnored

    package var errorDescription: String? {
        switch self {
        case .notARepository(let path):
            "\(path) is not a git repository."
        case .command(let message):
            message
        case .invalidBranchName:
            "Branch name is not valid."
        case .projectFolderNotIgnored:
            "Git still does not ignore \(WorktreePathPolicy.ignorePattern) after the change to .git/info/exclude. Look for a rule such as !\(WorktreePathPolicy.ignorePattern) in .gitignore."
        }
    }
}
