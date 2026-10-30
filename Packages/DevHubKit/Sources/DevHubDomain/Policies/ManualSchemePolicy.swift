import Foundation

package enum ManualSchemePolicy {

    package static func options(visible: [String], manual: [String]) -> [String] {
        visible + manual.filter { visible.contains($0) == false }
    }

    package static func adding(_ name: String, to manual: [String], visible: [String]) -> [String] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false, visible.contains(trimmed) == false, manual.contains(trimmed) == false else { return manual }
        return manual + [trimmed]
    }

    package static func suggestions(listed: [String], visible: [String], manual: [String]) -> [String] {
        listed.filter { visible.contains($0) == false && manual.contains($0) == false }
    }
}
