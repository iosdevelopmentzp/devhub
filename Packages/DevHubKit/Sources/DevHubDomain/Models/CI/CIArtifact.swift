import Foundation

package struct CIArtifact: Hashable, Sendable, Identifiable {
    package let path: String
    package let url: URL?

    package init(path: String, url: URL?) {
        self.path = path
        self.url = url
    }

    package var id: String {
        path
    }

    package var fileName: String {
        (path as NSString).lastPathComponent
    }
}
