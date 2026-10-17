import Foundation

nonisolated enum GitBranchParser {
    static let localFormat = "--format=%(refname:short)%09%(upstream:short)%09%(upstream:track,nobracket)%09%(committerdate:unix)%09%(worktreepath)%09%(contents:subject)"
    static let remoteFormat = "--format=%(refname:short)%09%(authorname)%09%(committerdate:unix)%09%(contents:subject)"

    static func parseLocal(_ output: String, merged: Set<String>, visits: [String: Date]) -> [GitBranch] {
        output.split(whereSeparator: \.isNewline).compactMap { line in
            let fields = line.split(separator: "\t", maxSplits: 5, omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 5, fields[0].isEmpty == false else { return nil }
            let track = parseTrack(fields[2])
            return GitBranch(
                name: fields[0],
                upstream: fields[1].isEmpty ? nil : fields[1],
                ahead: track.ahead,
                behind: track.behind,
                isUpstreamGone: track.gone,
                commitDate: TimeParsing.date(fields[3]),
                worktreePath: fields[4].isEmpty ? nil : fields[4],
                subject: fields.count > 5 ? fields[5] : "",
                lastVisit: visits[fields[0]],
                isMerged: merged.contains(fields[0])
            )
        }
    }

    static func parseRemote(_ output: String) -> [RemoteBranch] {
        let prefix = "origin/"
        return output.split(whereSeparator: \.isNewline).compactMap { line in
            let fields = line.split(separator: "\t", maxSplits: 3, omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 3, fields[0].hasPrefix(prefix), fields[0] != "origin/HEAD" else { return nil }
            return RemoteBranch(
                name: String(fields[0].dropFirst(prefix.count)),
                author: fields[1],
                date: TimeParsing.date(fields[2]) ?? .distantPast,
                subject: fields.count > 3 ? fields[3] : ""
            )
        }
    }

    static func parseNames(_ output: String) -> Set<String> {
        Set(output.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.isEmpty == false })
    }

    static func parseVisits(_ output: String) -> [String: Date] {
        var visits: [String: Date] = [:]
        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard fields.count == 2, fields[0].hasPrefix("checkout: moving from "), let date = TimeParsing.date(fields[1]) else { continue }
            let words = fields[0].split(separator: " ")
            guard let target = words.last, visits[String(target)] == nil else { continue }
            visits[String(target)] = date
        }
        return visits
    }

    private static func parseTrack(_ text: String) -> (ahead: Int, behind: Int, gone: Bool) {
        if text == "gone" {
            return (0, 0, true)
        }
        var ahead = 0
        var behind = 0
        for part in text.split(separator: ",") {
            let words = part.trimmingCharacters(in: .whitespaces).split(separator: " ")
            guard words.count == 2, let value = Int(words[1]) else { continue }
            if words[0] == "ahead" { ahead = value }
            if words[0] == "behind" { behind = value }
        }
        return (ahead, behind, false)
    }
}

nonisolated enum TimeParsing {
    static func date(_ unix: String) -> Date? {
        Double(unix.trimmingCharacters(in: .whitespaces)).map { Date(timeIntervalSince1970: $0) }
    }
}
