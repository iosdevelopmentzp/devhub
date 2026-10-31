import Foundation

package enum HiddenFilePolicy {
    package static let suggestedPatterns = ["*Tests/*", "*Tests.swift", "*.xcodeproj/*", "*.resolved", "*.lock"]

    package static func isHidden(_ path: String, patterns: [String]) -> Bool {
        let name = (path as NSString).lastPathComponent
        return patterns.contains { matches($0, path) || matches($0, name) }
    }

    package static func hiddenPaths(in paths: [String], patterns: [String]) -> Set<String> {
        guard patterns.isEmpty == false else { return [] }
        return Set(paths.filter { isHidden($0, patterns: patterns) })
    }

    package static func hiddenPaths(in paths: [String], patterns: [String], chosen: Set<String>) -> Set<String> {
        hiddenPaths(in: paths, patterns: patterns).union(paths.filter(chosen.contains))
    }

    package static func suggestedPaths(in paths: [String], hidden: Set<String>) -> [String] {
        paths.filter { hidden.contains($0) == false && isHidden($0, patterns: suggestedPatterns) }
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        fnmatch(pattern, text, 0) == 0
    }
}
