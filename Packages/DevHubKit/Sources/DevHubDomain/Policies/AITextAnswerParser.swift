import Foundation

package enum AITextAnswerParser {
    package static func clean(_ answer: String) -> String {
        var lines = answer
            .replacingOccurrences(of: "\u{1B}\\[[0-9;?]*[A-Za-z]", with: "", options: .regularExpression)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        while let first = lines.first, first.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeFirst()
        }
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        if let first = lines.first, first.hasPrefix("```"), let last = lines.last, last.trimmingCharacters(in: .whitespaces) == "```", lines.count >= 2 {
            lines = Array(lines.dropFirst().dropLast())
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    package static func titleAndBody(_ answer: String) -> (title: String, body: String) {
        let lines = clean(answer).split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let index = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }) else { return ("", "") }
        let title = stripped(lines[index], prefixes: ["# ", "Title:", "**Title:**"])
        var rest = Array(lines[(index + 1)...])
        if let first = rest.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty == false }),
           ["Description:", "**Description:**"].contains(rest[first].trimmingCharacters(in: .whitespaces)) {
            rest.remove(at: first)
        }
        return (title, rest.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func stripped(_ line: String, prefixes: [String]) -> String {
        var text = line.trimmingCharacters(in: .whitespaces)
        for prefix in prefixes where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return text.trimmingCharacters(in: CharacterSet(charactersIn: "\"`"))
    }
}
