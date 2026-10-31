import Foundation

package protocol TextFileRepository: Sendable {
    func write(_ text: String, to path: String) async throws
    func writeScratch(_ text: String, name: String) async throws -> String
}
