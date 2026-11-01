import Foundation

package struct AppContainers: Hashable, Sendable {
    package var app: String
    package var data: String
    package var groups: [AppDataFile] = []

    package static let none = AppContainers(app: "", data: "")

    package init(app: String, data: String, groups: [AppDataFile] = []) {
        self.app = app
        self.data = data
        self.groups = groups
    }
}
