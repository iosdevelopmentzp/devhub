import Foundation

package struct ExampleFile: Hashable, Sendable {
    package var path: String
    package var text: String
    package var isExecutable: Bool

    package init(
        path: String,
        text: String,
        isExecutable: Bool
    ) {
        self.path = path
        self.text = text
        self.isExecutable = isExecutable
    }
}
