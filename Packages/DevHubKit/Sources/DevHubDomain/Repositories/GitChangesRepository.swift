import Foundation

package protocol GitChangesRepository: Sendable {
    func changes(in path: String) async throws -> [GitFileChange]
    func diff(for change: GitFileChange, in path: String) async throws -> GitDiff
    func branchCommits(base: String, remote: String, in path: String) async throws -> [GitCommit]
    func commitFiles(hash: String, in path: String) async throws -> [GitCommitFile]
    func commitDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff
    func reflog(in path: String) async throws -> [GitReflogEntry]
}
