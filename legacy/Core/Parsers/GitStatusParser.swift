import Foundation

nonisolated enum GitStatusParser {
    static func parse(_ output: String) -> GitSummary {
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first, header.hasPrefix("## ") else { return .notARepository }
        let description = String(header.dropFirst(3))
        return GitSummary(
            branch: branchName(in: description),
            changeCount: lines.count - 1,
            ahead: count(after: "ahead ", in: description),
            behind: count(after: "behind ", in: description)
        )
    }

    private static func branchName(in description: String) -> String {
        if description.hasPrefix("No commits yet on ") {
            return String(description.dropFirst("No commits yet on ".count))
        }
        if description.hasPrefix("HEAD (no branch)") {
            return "detached HEAD"
        }
        let name = description.components(separatedBy: "...")[0]
        return name.components(separatedBy: " ")[0]
    }

    private static func count(after marker: String, in description: String) -> Int {
        guard let range = description.range(of: marker) else { return 0 }
        let digits = description[range.upperBound...].prefix { $0.isNumber }
        return Int(digits) ?? 0
    }
}
