import Foundation
import DevHubDomain

struct FileTextRepository: TextFileRepository {
    let scratchRoot: URL

    func write(_ text: String, to path: String) async throws {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    func writeScratch(_ text: String, name: String) async throws -> String {
        try FileManager.default.createDirectory(at: scratchRoot, withIntermediateDirectories: true)
        let file = scratchRoot.appendingPathComponent(name)
        try Data(text.utf8).write(to: file, options: .atomic)
        return file.path
    }
}
