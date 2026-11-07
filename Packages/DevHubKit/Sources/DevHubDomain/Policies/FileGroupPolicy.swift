import Foundation

package enum FileGroupPolicy {

    package static func matches(in paths: [String], groups: [PullRequestFileGroup]) -> [FileGroupMatch] {
        var remaining = paths
        return groups.compactMap { group in
            let matched = remaining.filter { HiddenFilePolicy.isHidden($0, patterns: group.patterns) }
            guard matched.isEmpty == false else { return nil }
            remaining.removeAll(where: matched.contains)
            return FileGroupMatch(name: group.name, paths: matched, isHiddenByDefault: group.isHiddenByDefault)
        }
    }

    package static func isHidden(_ match: FileGroupMatch, toggled: Set<String>) -> Bool {
        match.isHiddenByDefault != toggled.contains(match.name)
    }

    package static func hiddenPaths(in matches: [FileGroupMatch], toggled: Set<String>) -> Set<String> {
        Set(matches.filter { isHidden($0, toggled: toggled) }.flatMap(\.paths))
    }

    package static func groupName(of path: String, in matches: [FileGroupMatch]) -> String? {
        matches.first { $0.paths.contains(path) }?.name
    }

    package static func groupedPaths(in matches: [FileGroupMatch]) -> Set<String> {
        Set(matches.flatMap(\.paths))
    }
}
