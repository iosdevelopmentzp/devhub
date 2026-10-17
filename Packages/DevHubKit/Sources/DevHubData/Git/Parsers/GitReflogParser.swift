import Foundation
import DevHubDomain

enum GitReflogParser {
    static let format = ["%H", "%h", "%gd", "%gs"].joined(separator: "%x09")

    static func parse(_ reflog: String) -> [GitReflogEntry] {
        reflog.split(separator: "\n").enumerated().compactMap { index, line -> GitReflogEntry? in
            let fields = line.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 4 else { return nil }
            let (action, message) = split(fields[3])
            return GitReflogEntry(index: index, hash: fields[0], shortHash: fields[1], date: date(in: fields[2]), action: action, message: message)
        }
    }

    private static func date(in selector: String) -> Date? {
        guard let open = selector.firstIndex(of: "{"), let close = selector.lastIndex(of: "}"), open < close else { return nil }
        return TimeInterval(selector[selector.index(after: open)..<close]).map { Date(timeIntervalSince1970: $0) }
    }

    private static func split(_ subject: String) -> (String, String) {
        guard let range = subject.range(of: ": ") else { return (subject, "") }
        return (String(subject[..<range.lowerBound]), String(subject[range.upperBound...]))
    }
}
