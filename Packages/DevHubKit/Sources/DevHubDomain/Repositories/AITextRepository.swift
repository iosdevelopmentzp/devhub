import Foundation

package protocol AITextRepository: Sendable {
    func generate(prompt: String, command: String, cwd: String?) async throws -> String
}
