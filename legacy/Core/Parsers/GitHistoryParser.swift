import Foundation

nonisolated enum GitHistoryParser {
    static let logFormat = "--format=%H%x09%an%x09%ct%x09%s"

    static func parseLog(_ output: String, unpushed: Set<String>) -> [GitCommit] {
        output.split(whereSeparator: \.isNewline).compactMap { line in
            let fields = line.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 4, let date = TimeParsing.date(fields[2]) else { return nil }
            return GitCommit(hash: fields[0], author: fields[1], date: date, subject: fields[3], isPushed: unpushed.contains(fields[0]) == false)
        }
    }

    static func parseDistance(_ output: String) -> BranchDistance? {
        let numbers = output.split(whereSeparator: { $0 == "\t" || $0 == " " || $0.isNewline }).compactMap { Int($0) }
        guard numbers.count == 2 else { return nil }
        return BranchDistance(ahead: numbers[0], behind: numbers[1])
    }
}
