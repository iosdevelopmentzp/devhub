import Foundation

package protocol RedactionWordsRepository: Sendable {
    func words() async throws -> [RedactionWord]
}
