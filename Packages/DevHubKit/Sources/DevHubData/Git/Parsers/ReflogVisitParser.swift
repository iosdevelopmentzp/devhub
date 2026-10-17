import Foundation

enum ReflogVisitParser {
    static func parse(_ reflog: String) -> [String: Date] {
        var result: [String: Date] = [:]
        for line in reflog.split(separator: "\n") {
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard parts.count == 2, let seconds = TimeInterval(parts[1]) else { continue }
            let message = String(parts[0])
            guard message.hasPrefix("checkout: moving from "), let range = message.range(of: " to ", options: .backwards) else { continue }
            let target = String(message[range.upperBound...])
            let date = Date(timeIntervalSince1970: seconds)
            if let existing = result[target], existing >= date { continue }
            result[target] = date
        }
        return result
    }
}
