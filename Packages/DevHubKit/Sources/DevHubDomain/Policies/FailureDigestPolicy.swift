import Foundation

package enum FailureDigestPolicy {
    package static let lineLimit = 8
    package static let tailLimit = 6

    private static let tellingWords = [
        "error", "fatal", "failed", "failure", "rejected", "conflict", "denied", "not found", "no such",
        "cannot", "can't", "could not", "couldn't", "unable", "invalid", "refused", "abort", "exception",
        "permission", "timed out", "hint:"
    ]

    package static func digest(_ lines: [String]) -> [String] {
        let cleaned = lines.map(clean).filter { $0.isEmpty == false }
        let telling = cleaned.filter(isTelling)
        let picked = telling.isEmpty ? Array(cleaned.suffix(tailLimit)) : Array(telling.suffix(lineLimit))
        return unique(picked)
    }

    package static func clean(_ line: String) -> String {
        line.replacingOccurrences(of: "\u{1B}\\[[0-9;?]*[A-Za-z]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isTelling(_ line: String) -> Bool {
        let lowered = line.lowercased()
        return lowered.hasPrefix("! ") || tellingWords.contains { lowered.contains($0) }
    }

    private static func unique(_ lines: [String]) -> [String] {
        var seen: Set<String> = []
        return lines.filter { seen.insert($0).inserted }
    }
}
