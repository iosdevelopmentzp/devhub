import Foundation

nonisolated enum CommitPrefix {
    static let defaultPattern = "^([A-Z]+-\\d+)"
    static let defaultFormat = "$1: "

    static func make(branch: String, pattern: String?, format: String?) -> String {
        let source = pattern ?? defaultPattern
        guard let expression = try? NSRegularExpression(pattern: source) else { return "" }
        let name = branch.split(separator: "/").last.map(String.init) ?? branch
        for candidate in [branch, name] {
            let span = NSRange(candidate.startIndex..., in: candidate)
            guard let match = expression.firstMatch(in: candidate, range: span) else { continue }
            return expansion(of: format ?? defaultFormat, match: match, in: candidate)
        }
        return ""
    }

    private static func expansion(of format: String, match: NSTextCheckingResult, in text: String) -> String {
        var result = format
        for index in stride(from: match.numberOfRanges - 1, through: 0, by: -1) {
            guard let range = Range(match.range(at: index), in: text) else { continue }
            result = result.replacingOccurrences(of: "$\(index)", with: String(text[range]))
        }
        return result
    }
}
