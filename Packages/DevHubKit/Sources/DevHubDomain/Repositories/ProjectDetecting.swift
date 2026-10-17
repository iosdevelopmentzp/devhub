import Foundation

package protocol ProjectDetecting: Sendable {
    func project(at folder: URL) -> Project
    func isGitRepository(_ folder: URL) -> Bool
}
