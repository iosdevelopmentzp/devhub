import Foundation
import DevHubDomain

struct MockTextFileRepository: TextFileRepository {

    func write(_ text: String, to path: String) async throws {}

    func writeScratch(_ text: String, name: String) async throws -> String {
        "~/.devhub/scratch/\(name)"
    }
}
