import Foundation
import DevHubDomain

struct FileReviewPromptRepository: ReviewPromptRepository {
    let root: URL

    func save(_ prompt: String, iid: Int) async throws -> String {
        try await save(prompt, name: "mr-\(iid)")
    }

    func save(_ prompt: String, name: String) async throws -> String {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("\(name).md")
        try Data(prompt.utf8).write(to: file, options: .atomic)
        return file.path
    }
}
