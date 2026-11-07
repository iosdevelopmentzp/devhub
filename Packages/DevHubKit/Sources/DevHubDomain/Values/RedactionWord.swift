import Foundation

package enum RedactionWord: Hashable, Sendable {
    case word(String)
    case pattern(String)

    package static func parse(_ text: String) -> [RedactionWord] {
        text.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.isEmpty == false, trimmed.hasPrefix("#") == false else { return nil }
            guard trimmed.hasPrefix("re:") else { return .word(trimmed) }
            let pattern = trimmed.dropFirst(3).trimmingCharacters(in: .whitespaces)
            return pattern.isEmpty ? nil : .pattern(pattern)
        }
    }
}
