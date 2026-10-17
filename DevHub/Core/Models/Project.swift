import Foundation

nonisolated struct Project: Identifiable, Hashable, Sendable, Codable {
    let path: String

    var id: String { path }

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
