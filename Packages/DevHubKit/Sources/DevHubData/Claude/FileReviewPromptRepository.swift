import Foundation
import DevHubDomain

struct FileReviewPromptRepository: ReviewPromptRepository {
    let root: URL

    func save(_ prompt: String, iid: Int) async throws -> String {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("mr-\(iid).md")
        try Data(prompt.utf8).write(to: file, options: .atomic)
        return file.path
    }
}
