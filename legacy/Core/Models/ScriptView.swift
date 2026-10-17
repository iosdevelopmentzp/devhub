import Foundation

nonisolated struct ScriptView: Codable, Hashable, Sendable {
    var rows: [ScriptViewRow]?
    var keyValues: [[String]]?
    var text: String?

    var pairs: [(String, String)] {
        (keyValues ?? []).compactMap { pair in
            guard pair.count >= 2 else { return nil }
            return (pair[0], pair[1])
        }
    }

    var isEmpty: Bool {
        (rows ?? []).isEmpty && pairs.isEmpty && (text ?? "").isEmpty
    }
}

nonisolated struct ScriptViewRow: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var title: String
    var subtitle: String?
    var tags: [ScriptViewTag]?
    var actions: [ScriptViewAction]?
}

nonisolated struct ScriptViewTag: Codable, Hashable, Sendable {
    var text: String
    var tint: Tint?
}

nonisolated struct ScriptViewAction: Codable, Hashable, Sendable {
    var title: String
    var run: ActionRun
    var confirm: String?
}
