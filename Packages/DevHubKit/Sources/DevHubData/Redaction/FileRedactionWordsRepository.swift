import Foundation
import DevHubDomain

struct FileRedactionWordsRepository: RedactionWordsRepository {
    let file: URL

    func words() async throws -> [RedactionWord] {
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        let text = try String(contentsOf: file, encoding: .utf8)
        return RedactionWord.parse(text)
    }
}
