import Foundation

package struct ScriptView: Codable, Hashable, Sendable {
    package var rows: [ScriptViewRow]? = nil
    package var keyValues: [[String]]? = nil
    package var text: String? = nil

    package var pairs: [(String, String)] {
        (keyValues ?? []).compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return (pair[0], pair[1])
        }
    }

    package var isEmpty: Bool {
        (rows ?? []).isEmpty && pairs.isEmpty && (text ?? "").isEmpty
    }

    package init(
        rows: [ScriptViewRow]? = nil,
        keyValues: [[String]]? = nil,
        text: String? = nil
    ) {
        self.rows = rows
        self.keyValues = keyValues
        self.text = text
    }
}
