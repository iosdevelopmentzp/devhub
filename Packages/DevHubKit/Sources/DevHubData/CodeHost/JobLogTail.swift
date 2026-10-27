import Foundation
import DevHubDomain

enum JobLogTail {
    static let lineLimit = 200

    static func text(from data: Data, limit: Int = lineLimit) -> String {
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { stripTimestampAndColor(String($0)) }
        let trimmed = lines.last?.isEmpty == true ? Array(lines.dropLast()) : lines
        return LogRedactor.redact(trimmed.suffix(limit).joined(separator: "\n"))
    }

    private static let colorCodes = try? NSRegularExpression(pattern: #"\u001B\[[0-9;]*[A-Za-z]"#)
    private static let timestamp = try? NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z "#)

    private static func stripTimestampAndColor(_ line: String) -> String {
        [colorCodes, timestamp].compactMap { $0 }.reduce(line) { result, regex in
            regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
    }
}
