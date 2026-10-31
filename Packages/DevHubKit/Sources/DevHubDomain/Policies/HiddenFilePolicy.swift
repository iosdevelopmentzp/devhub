import Foundation

package enum HiddenFilePolicy {
    package static func isHidden(_ path: String, patterns: [String]) -> Bool {
        let name = (path as NSString).lastPathComponent
        return patterns.contains { matches($0, path) || matches($0, name) }
    }

    package static func hiddenPaths(in paths: [String], patterns: [String]) -> Set<String> {
        guard patterns.isEmpty == false else { return [] }
        return Set(paths.filter { isHidden($0, patterns: patterns) })
    }

    private static func matches(_ pattern: String, _ text: String) -> Bool {
        fnmatch(pattern, text, 0) == 0
    }
}
