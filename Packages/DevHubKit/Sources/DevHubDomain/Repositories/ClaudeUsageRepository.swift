import Foundation

package protocol ClaudeUsageRepository: Sendable {
    func fetch() async throws -> ClaudeUsage
}
