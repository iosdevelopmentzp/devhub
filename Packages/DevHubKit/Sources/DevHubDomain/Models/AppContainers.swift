import Foundation

package struct AppContainers: Hashable, Sendable {
    package var app: String
    package var data: String

    package static let none = AppContainers(app: "", data: "")

    package init(app: String, data: String) {
        self.app = app
        self.data = data
    }
}
