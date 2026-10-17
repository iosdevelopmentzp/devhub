import Foundation

package struct InputOption: Codable, Hashable, Sendable {
    package var value: String
    package var title: String? = nil

    package var label: String {
        title ?? value
    }

    package init(
        value: String,
        title: String? = nil
    ) {
        self.value = value
        self.title = title
    }
}
