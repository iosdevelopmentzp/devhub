import Foundation

nonisolated enum GitStatusV2Parser {
    static func parse(_ output: String) -> GitStatus {
        var status = GitStatus.empty
        var fields = output.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)[...]
        while let field = fields.popFirst() {
            if field.hasPrefix("# ") {
                applyHeader(field, to: &status)
            } else if field.hasPrefix("1 ") {
                append(entry: field, pathIndex: 8, original: nil, to: &status)
            } else if field.hasPrefix("2 ") {
                append(entry: field, pathIndex: 9, original: fields.popFirst(), to: &status)
            } else if field.hasPrefix("u ") {
                append(entry: field, pathIndex: 10, original: nil, to: &status, conflict: true)
            } else if field.hasPrefix("? ") {
                let path = String(field.dropFirst(2))
                status.changes.append(GitChange(path: path, originalPath: nil, index: "?", worktree: "?"))
            }
        }
        return status
    }

    private static func applyHeader(_ field: String, to status: inout GitStatus) {
        let parts = field.dropFirst(2).split(separator: " ", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        switch parts[0] {
        case "branch.oid":
            status.objectID = parts[1] == "(initial)" ? nil : parts[1]
        case "branch.head":
            status.branch = parts[1] == "(detached)" ? nil : parts[1]
        case "branch.upstream":
            status.upstream = parts[1]
        case "branch.ab":
            let numbers = parts[1].split(separator: " ")
            status.ahead = numbers.first.flatMap { Int($0.dropFirst()) } ?? 0
            status.behind = numbers.last.flatMap { Int($0.dropFirst()) } ?? 0
        default:
            break
        }
    }

    private static func append(entry: String, pathIndex: Int, original: String?, to status: inout GitStatus, conflict: Bool = false) {
        let parts = entry.split(separator: " ", maxSplits: pathIndex, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == pathIndex + 1, parts[1].count == 2 else { return }
        let code = Array(parts[1])
        let index: Character = conflict ? "u" : code[0]
        let worktree: Character = conflict ? "u" : code[1]
        status.changes.append(GitChange(path: parts[pathIndex], originalPath: original, index: index, worktree: worktree))
    }
}
