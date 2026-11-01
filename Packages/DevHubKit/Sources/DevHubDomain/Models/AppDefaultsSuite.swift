import Foundation

package struct AppDefaultsSuite: Identifiable, Hashable, Sendable {
    package var name: String
    package var plistPath: String
    package var entries: [AppDefault]

    package var id: String {
        name
    }

    package init(name: String, plistPath: String, entries: [AppDefault]) {
        self.name = name
        self.plistPath = plistPath
        self.entries = entries
    }
}
