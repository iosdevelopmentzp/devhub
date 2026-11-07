import Foundation
import DevHubDomain

enum GitStashParser {
    static func parse(_ output: String) -> [GitStash] {
        output.split(separator: "\n").compactMap { line -> GitStash? in
            let fields = line.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 4, let index = index(fields[0]) else { return nil }
            let (branch, message) = subject(fields[3])
            return GitStash(
                index: index,
                hash: fields[1],
                branch: branch,
                message: message,
                date: TimeInterval(fields[2]).map { Date(timeIntervalSince1970: $0) }
            )
        }
    }

    private static func index(_ ref: String) -> Int? {
        guard let open = ref.firstIndex(of: "{"), let close = ref.lastIndex(of: "}"), open < close else { return nil }
        return Int(ref[ref.index(after: open)..<close])
    }

    private static func subject(_ text: String) -> (branch: String?, message: String) {
        if text.hasPrefix("WIP on "), let colon = text.range(of: ": ") {
            let branch = String(text[text.index(text.startIndex, offsetBy: 7)..<colon.lowerBound])
            let rest = text[colon.upperBound...]
            let commit = rest.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? String(rest)
            return (name(branch), "WIP: \(commit)")
        }
        if text.hasPrefix("On "), let colon = text.range(of: ": ") {
            let branch = String(text[text.index(text.startIndex, offsetBy: 3)..<colon.lowerBound])
            return (name(branch), String(text[colon.upperBound...]))
        }
        return (nil, text)
    }

    private static func name(_ branch: String) -> String? {
        branch == "(no branch)" ? nil : branch
    }
}
