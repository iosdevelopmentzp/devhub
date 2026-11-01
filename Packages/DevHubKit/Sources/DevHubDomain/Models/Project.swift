import Foundation

package struct Project: Identifiable, Hashable, Codable, Sendable {
    package let id: String
    package var name: String
    package var path: String
    package var scheme: String
    package var bundleID: String
    package var developerDir: String? = nil

    package static let none = Project(id: "", name: "No project", path: "", scheme: "", bundleID: "")

    package init(
        id: String,
        name: String,
        path: String,
        scheme: String,
        bundleID: String,
        developerDir: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.scheme = scheme
        self.bundleID = bundleID
        self.developerDir = developerDir
    }
}
