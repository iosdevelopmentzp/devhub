import Foundation

extension [LaunchProfile] {
    package func profile(matching value: String?) -> LaunchProfile? {
        guard let value = value?.trimmed, value.isEmpty == false else { return nil }
        return first { $0.id == value } ?? first { $0.title.caseInsensitiveCompare(value) == .orderedSame }
    }
}
