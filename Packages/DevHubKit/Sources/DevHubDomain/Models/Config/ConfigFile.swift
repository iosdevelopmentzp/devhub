import Foundation

package struct ConfigFile: Hashable, Sendable {
    package var name: String
    package var text: String

    package init(
        name: String,
        text: String
    ) {
        self.name = name
        self.text = text
    }
}
