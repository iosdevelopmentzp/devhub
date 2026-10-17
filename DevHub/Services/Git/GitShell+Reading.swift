import Foundation

nonisolated extension GitShell {
    func status(at path: String) async throws -> GitStatus {
        let text = try await output(["status", "--porcelain=v2", "--branch", "-z", "--untracked-files=all"], at: path)
        return GitStatusV2Parser.parse(text)
    }

    func branches(at path: String, base: String) async throws -> BranchSnapshot {
        async let localText = output(["for-each-ref", "refs/heads", GitBranchParser.localFormat], at: path)
        async let remoteText = output(["for-each-ref", "refs/remotes/origin", "--sort=-committerdate", GitBranchParser.remoteFormat], at: path)
        async let mergedText = optionalOutput(["branch", "--merged", base, "--format=%(refname:short)"], at: path)
        async let reflogText = optionalOutput(["reflog", "show", "--format=%gs%x09%ct", "-n", "3000", "HEAD"], at: path)
        let merged = await mergedText.map(GitBranchParser.parseNames) ?? []
        let visits = await reflogText.map(GitBranchParser.parseVisits) ?? [:]
        let local = GitBranchParser.parseLocal(try await localText, merged: merged, visits: visits)
        let remote = GitBranchParser.parseRemote(try await remoteText)
        return BranchSnapshot(local: sorted(local), remote: remote)
    }

    func details(at path: String, base: String) async -> CheckoutDetails {
        async let layout = optionalOutput(
            ["rev-parse", "--git-common-dir", "--git-path", "rebase-merge", "--git-path", "rebase-apply", "--git-path", "MERGE_HEAD", "--git-path", "CHERRY_PICK_HEAD"],
            at: path
        )
        async let stash = optionalOutput(["stash", "list"], at: path)
        async let distance = optionalOutput(["rev-list", "--left-right", "--count", "HEAD...\(base)"], at: path)
        let lines = (await layout ?? "").split(whereSeparator: \.isNewline).map(String.init)
        return CheckoutDetails(
            operation: operation(lines: lines, path: path),
            lastFetch: lastFetch(lines: lines, path: path),
            stashCount: (await stash ?? "").split(whereSeparator: \.isNewline).count,
            distance: (await distance).flatMap(GitHistoryParser.parseDistance)
        )
    }

    func history(at path: String, limit: Int) async throws -> [GitCommit] {
        async let log = output(["log", "-n", String(limit), GitHistoryParser.logFormat], at: path)
        async let unpushed = optionalOutput(["rev-list", "-n", String(limit), "HEAD", "--not", "--remotes=origin"], at: path)
        let hashes = Set((await unpushed ?? "").split(whereSeparator: \.isNewline).map(String.init))
        return GitHistoryParser.parseLog(try await log, unpushed: hashes)
    }

    func diff(at path: String, change: GitChange, group: GitChange.Group) async throws -> GitDiff {
        if group == .untracked {
            return Self.newFileDiff(at: path, change: change)
        }
        var arguments = ["diff", "--no-color", "--no-ext-diff"]
        if group == .staged {
            arguments.append("--cached")
        }
        arguments += ["--"] + [change.originalPath, change.path].compactMap { $0 }
        return GitDiff(text: try await output(arguments, at: path))
    }

    private func sorted(_ branches: [GitBranch]) -> [GitBranch] {
        branches.sorted { first, second in
            if (first.lastVisit != nil) != (second.lastVisit != nil) {
                return first.lastVisit != nil
            }
            return first.sortDate > second.sortDate
        }
    }

    private func operation(lines: [String], path: String) -> GitOperation? {
        guard lines.count == 5 else { return nil }
        let candidates: [(String, GitOperation)] = [(lines[1], .rebase), (lines[2], .rebase), (lines[3], .merge), (lines[4], .cherryPick)]
        return candidates.first { FileManager.default.fileExists(atPath: Self.resolve($0.0, in: path)) }?.1
    }

    private func lastFetch(lines: [String], path: String) -> Date? {
        guard let common = lines.first else { return nil }
        let file = Self.resolve(common, in: path) + "/FETCH_HEAD"
        return (try? FileManager.default.attributesOfItem(atPath: file))?[.modificationDate] as? Date
    }

    private static func resolve(_ reported: String, in path: String) -> String {
        reported.hasPrefix("/") ? reported : path + "/" + reported
    }

    private static func newFileDiff(at path: String, change: GitChange) -> GitDiff {
        let url = URL(fileURLWithPath: path + "/" + change.path)
        guard let handle = try? FileHandle(forReadingFrom: url) else { return .empty }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: 2_000_000)) ?? Data()
        if data.contains(0) {
            return .binary
        }
        let text = String(decoding: data, as: UTF8.self)
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { "+" + $0 }
        let body = lines.last == "+" ? Array(lines.dropLast()) : lines
        return GitDiff(lines: ["New file: \(change.path)"] + Array(body.prefix(GitDiff.lineLimit)), isBinary: false, hiddenLineCount: max(0, body.count - GitDiff.lineLimit))
    }
}
