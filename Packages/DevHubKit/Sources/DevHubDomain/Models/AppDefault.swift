import Foundation

package struct AppDefault: Identifiable, Hashable, Sendable {
    package enum Kind: String, CaseIterable, Hashable, Sendable {
        case string
        case integer
        case float
        case bool
        case date
        case data
        case array
        case dictionary
    }

    package var key: String
    package var kind: Kind
    package var text: String

    package var id: String {
        key
    }

    package init(key: String, kind: Kind, text: String) {
        self.key = key
        self.kind = kind
        self.text = text
    }
}
