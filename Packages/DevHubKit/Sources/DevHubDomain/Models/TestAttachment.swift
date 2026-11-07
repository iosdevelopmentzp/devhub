import Foundation

package struct TestAttachment: Hashable, Sendable {
    package var testIdentifier: String
    package var name: String
    package var path: String
    package var isAssociatedWithFailure: Bool

    package init(testIdentifier: String, name: String, path: String, isAssociatedWithFailure: Bool) {
        self.testIdentifier = testIdentifier
        self.name = name
        self.path = path
        self.isAssociatedWithFailure = isAssociatedWithFailure
    }

    package var isImage: Bool {
        ["png", "jpg", "jpeg", "heic", "gif", "tiff"].contains((path as NSString).pathExtension.lowercased())
    }
}
