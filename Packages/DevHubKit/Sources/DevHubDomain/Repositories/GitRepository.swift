import Foundation

package protocol GitRepository: Sendable {
    func state(checkoutPath: String, mainPath: String, settings: GitSettings) async throws -> GitRepositoryState
    func perform(_ command: GitCommand, in path: String) async throws
    func webURL(checkoutPath: String, remote: String) async -> URL?
    func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String]
    func pullRequestTemplate(in path: String) async -> String?
}
