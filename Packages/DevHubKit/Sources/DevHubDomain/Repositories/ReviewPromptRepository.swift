import Foundation

package protocol ReviewPromptRepository: Sendable {
    func save(_ prompt: String, iid: Int) async throws -> String
}
