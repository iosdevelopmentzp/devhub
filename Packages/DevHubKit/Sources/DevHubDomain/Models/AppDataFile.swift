import Foundation

package struct AppDataFile: Identifiable, Hashable, Sendable {
    package var name: String
    package var path: String
    package var size: Int64

    package var id: String {
        path
    }

    package init(name: String, path: String, size: Int64) {
        self.name = name
        self.path = path
        self.size = size
    }
}
