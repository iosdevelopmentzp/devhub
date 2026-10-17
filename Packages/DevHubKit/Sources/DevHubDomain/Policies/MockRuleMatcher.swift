import Foundation

package enum MockRuleMatcher {

    package static func match(method: String, path: String, query: String?, in rules: [MockRule]) -> MockRule? {
        rules.first { $0.isEnabled && matches($0, method: method, path: path, query: query) }
    }

    package static func matches(_ rule: MockRule, method: String, path: String, query: String?) -> Bool {
        if let ruleMethod = rule.method?.trimmed, ruleMethod.isEmpty == false, ruleMethod.caseInsensitiveCompare(method) != .orderedSame {
            return false
        }
        return pathMatches(pattern: rule.pathPattern, path: path) && queryMatches(required: rule.query, query: query)
    }

    package static func pathMatches(pattern: String, path: String) -> Bool {
        let patternSegments = segments(of: pattern)
        let pathSegments = segments(of: path)
        return match(patternSegments[...], pathSegments[...])
    }

    package static func queryMatches(required: String?, query: String?) -> Bool {
        let wanted = pairs(of: required ?? "")
        guard wanted.isEmpty == false else { return true }
        let present = pairs(of: query ?? "")
        return wanted.allSatisfy { want in
            present.contains { $0.key == want.key && (want.value == nil || $0.value == want.value) }
        }
    }

    private static func segments(of path: String) -> [Substring] {
        let trimmed = path.trimmed
        let withoutQuery = trimmed.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
        return withoutQuery.split(separator: "/")
    }

    private static func match(_ pattern: ArraySlice<Substring>, _ path: ArraySlice<Substring>) -> Bool {
        guard let head = pattern.first else { return path.isEmpty }
        if head == "**" {
            let rest = pattern.dropFirst()
            return path.indices.contains { match(rest, path[$0...]) } || match(rest, path[path.endIndex...])
        }
        guard let segment = path.first, segmentMatches(pattern: head, segment: segment) else { return false }
        return match(pattern.dropFirst(), path.dropFirst())
    }

    private static func segmentMatches(pattern: Substring, segment: Substring) -> Bool {
        guard pattern.contains("*") else { return pattern == segment }
        let pieces = pattern.split(separator: "*", omittingEmptySubsequences: false)
        var remainder = segment[...]
        for (index, piece) in pieces.enumerated() {
            if index == 0 {
                guard remainder.hasPrefix(piece) else { return false }
                remainder = remainder.dropFirst(piece.count)
            } else if index == pieces.count - 1 {
                return piece.isEmpty || remainder.hasSuffix(piece)
            } else if piece.isEmpty == false {
                guard let range = remainder.range(of: piece) else { return false }
                remainder = remainder[range.upperBound...]
            }
        }
        return remainder.isEmpty
    }

    private static func pairs(of query: String) -> [(key: String, value: String?)] {
        let text = query.hasPrefix("?") ? String(query.dropFirst()) : query
        return text.split(separator: "&").compactMap { item in
            let parts = item.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let key = parts.first.map(decoded), key.isEmpty == false else { return nil }
            return (key, parts.count > 1 ? decoded(parts[1]) : nil)
        }
    }

    private static func decoded(_ text: Substring) -> String {
        let plus = text.replacingOccurrences(of: "+", with: " ")
        return plus.removingPercentEncoding ?? plus
    }
}
