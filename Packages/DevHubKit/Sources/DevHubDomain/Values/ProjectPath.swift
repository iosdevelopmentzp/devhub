import Foundation

package struct ProjectPath: Hashable, Sendable {
    package let raw: String

    package init(_ raw: String) {
        self.raw = raw
    }

    package var expanded: String {
        (raw as NSString).expandingTildeInPath
    }

    package var abbreviated: String {
        (raw as NSString).abbreviatingWithTildeInPath
    }

    package var url: URL {
        URL(fileURLWithPath: expanded)
    }
}
