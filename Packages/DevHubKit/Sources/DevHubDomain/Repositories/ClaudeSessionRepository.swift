import Foundation

package protocol ClaudeSessionRepository: Sendable {
    func sessions() async -> [ClaudeSession]
}
