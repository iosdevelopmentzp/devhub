import Foundation
import DevHubDomain

struct ShellWorktreeRepository: WorktreeRepository {
    let shell: ShellRunner
    let git: GitCommandRunner
    let mergedBranches: MergedBranchesQuery

    private static let agentFolder = ".claude/worktrees"
    private static let bootstrapScript = "init.sh"
    private static let bootstrapMarker = "Carthage/Build"
    private static let includeFile = ".worktreeinclude"

    init(shell: ShellRunner) {
        self.shell = shell
        git = GitCommandRunner(shell: shell)
        mergedBranches = MergedBranchesQuery(git: git)
    }

    func list(projectPath: String) async throws -> [Worktree] {
        let root = (projectPath as NSString).expandingTildeInPath
        let listing = try await git.run(["worktree", "list", "--porcelain"], in: root)
        let entries = WorktreePorcelainParser.parse(listing)
        guard let mainPath = entries.first?.path else { throw WorktreeError.notARepository(projectPath) }

        async let merged = merged(in: root)
        async let tracking = trackingInfo(in: root)
        let (mergedSet, trackingMap) = await (merged, tracking)

        return await withTaskGroup(of: (Int, Worktree).self) { group in
            for (index, entry) in entries.enumerated() {
                group.addTask {
                    (index, await details(for: entry, index: index, mainPath: mainPath, merged: mergedSet, tracking: trackingMap))
                }
            }
            var result: [(Int, Worktree)] = []
            for await item in group {
                result.append(item)
            }
            return result.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    func baseBranch(projectPath: String) async -> String {
        let root = (projectPath as NSString).expandingTildeInPath
        let reference = (try? await git.run(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], in: root))?.trimmed
        return reference?.isEmpty == false ? reference! : "origin/main"
    }

    func fetch(projectPath: String) async throws {
        _ = try await git.run(["fetch", "--prune", "origin"], in: (projectPath as NSString).expandingTildeInPath)
    }

    func remove(_ worktree: Worktree, projectPath: String) async throws {
        let root = (projectPath as NSString).expandingTildeInPath
        var arguments = ["worktree", "remove"]
        if worktree.isDirty || worktree.isLocked {
            arguments += ["--force", "--force"]
        }
        _ = try await git.run(arguments + [worktree.path], in: root)
    }

    func deleteBranch(_ branch: String, projectPath: String) async throws {
        _ = try await git.run(["branch", "-d", branch], in: (projectPath as NSString).expandingTildeInPath)
    }

    func prune(projectPath: String) async throws {
        _ = try await git.run(["worktree", "prune"], in: (projectPath as NSString).expandingTildeInPath)
    }

    func create(branch: String, base: String, projectPath: String) async throws -> NewWorktree {
        let root = (projectPath as NSString).expandingTildeInPath
        let check = try await git.result(["check-ref-format", "--branch", branch], in: root)
        guard check.exitCode == 0 else { throw WorktreeError.invalidBranchName }

        let path = worktreePath(for: branch, root: root)
        let localExists = (try? await git.run(["rev-parse", "--verify", "--quiet", "refs/heads/\(branch)"], in: root)) != nil
        let remoteExists = (try? await git.run(["rev-parse", "--verify", "--quiet", "refs/remotes/origin/\(branch)"], in: root)) != nil

        if localExists {
            _ = try await git.run(["worktree", "add", path, branch], in: root)
        } else if remoteExists {
            _ = try await git.run(["worktree", "add", "--track", "-b", branch, path, "origin/\(branch)"], in: root)
        } else {
            _ = try await git.run(["worktree", "add", "--no-track", "-b", branch, path, base], in: root)
        }
        copyIncludedFiles(from: root, to: path)
        return NewWorktree(path: path, branch: branch)
    }

    func bootstrap(worktreePath: String, onLine: @escaping @Sendable (String) -> Void) async throws {
        let path = (worktreePath as NSString).expandingTildeInPath
        let exitCode = try await shell.stream("bash", [Self.bootstrapScript], cwd: path, onLine: onLine)
        try Task.checkCancellation()
        guard exitCode == 0 else { throw WorktreeError.command("\(Self.bootstrapScript) exited with code \(exitCode).") }
    }

    // MARK: Details

    private func details(
        for entry: WorktreePorcelainParser.Entry,
        index: Int,
        mainPath: String,
        merged: Set<String>,
        tracking: [String: TrackingInfoParser.Tracking]
    ) async -> Worktree {
        let exists = FileManager.default.fileExists(atPath: entry.path)
        var worktree = Worktree(
            id: entry.path,
            path: entry.path,
            branch: entry.branch,
            head: String(entry.head.prefix(9)),
            kind: kind(of: entry.path, index: index, mainPath: mainPath),
            isLocked: entry.isLocked,
            isMissing: entry.isPrunable || exists == false,
            changedFiles: 0,
            upstream: nil,
            isUpstreamGone: false,
            ahead: 0,
            behind: 0,
            isMerged: false,
            lastCommit: "",
            lastActivity: nil,
            needsBootstrap: false
        )
        guard worktree.isMissing == false else { return worktree }

        if let branch = entry.branch {
            let info = tracking[branch]
            worktree.upstream = info?.upstream
            worktree.isUpstreamGone = info?.isGone ?? false
            worktree.ahead = info?.ahead ?? 0
            worktree.behind = info?.behind ?? 0
            worktree.isMerged = index > 0 && MergedBranchPolicy.isMerged(
                branch: branch,
                upstream: info?.upstream,
                ahead: info?.ahead ?? 0,
                mergedBranches: merged
            )
        }

        async let status = try? git.run(["status", "--porcelain"], in: entry.path)
        async let log = try? git.run(["log", "-1", "--format=%s%n%ct"], in: entry.path)
        let (statusOutput, logOutput) = await (status, log)

        worktree.changedFiles = statusOutput?.split(separator: "\n").count ?? 0
        let logLines = logOutput?.split(separator: "\n", maxSplits: 1).map(String.init) ?? []
        worktree.lastCommit = logLines.first ?? ""
        if logLines.count > 1, let seconds = TimeInterval(logLines[1].trimmed) {
            worktree.lastActivity = Date(timeIntervalSince1970: seconds)
        }
        worktree.needsBootstrap = needsBootstrap(entry.path, mainPath: mainPath)
        return worktree
    }

    private func kind(of path: String, index: Int, mainPath: String) -> Worktree.Kind {
        if index == 0 { return .main }
        return path.hasPrefix((mainPath as NSString).appendingPathComponent(Self.agentFolder) + "/") ? .agent : .linked
    }

    private func needsBootstrap(_ path: String, mainPath: String) -> Bool {
        let manager = FileManager.default
        guard manager.fileExists(atPath: (path as NSString).appendingPathComponent(Self.bootstrapScript)) else { return false }
        guard manager.fileExists(atPath: (mainPath as NSString).appendingPathComponent(Self.bootstrapMarker)) else { return false }
        return manager.fileExists(atPath: (path as NSString).appendingPathComponent(Self.bootstrapMarker)) == false
    }

    private func trackingInfo(in root: String) async -> [String: TrackingInfoParser.Tracking] {
        let format = "%(refname:short)%09%(upstream:short)%09%(upstream:track,nobracket)"
        guard let output = try? await git.run(["for-each-ref", "--format=\(format)", "refs/heads"], in: root) else { return [:] }
        return TrackingInfoParser.parse(output)
    }

    private func merged(in root: String) async -> Set<String> {
        let base = await baseBranch(projectPath: root)
        return await mergedBranches.branches(mergedInto: base, in: root)
    }

    // MARK: Create helpers

    private func worktreePath(for branch: String, root: String) -> String {
        let folderName = branch.replacingOccurrences(of: "/", with: "-")
        let agentFolder = (root as NSString).appendingPathComponent(Self.agentFolder)
        if FileManager.default.fileExists(atPath: agentFolder) {
            return (agentFolder as NSString).appendingPathComponent(folderName)
        }
        let parent = (root as NSString).deletingLastPathComponent
        return (parent as NSString).appendingPathComponent("\((root as NSString).lastPathComponent)-\(folderName)")
    }

    private func copyIncludedFiles(from root: String, to path: String) {
        let includeURL = URL(fileURLWithPath: root).appendingPathComponent(Self.includeFile)
        guard let content = try? String(contentsOf: includeURL, encoding: .utf8) else { return }
        let manager = FileManager.default
        for rawLine in content.split(separator: "\n") {
            let line = String(rawLine).trimmed
            guard line.isEmpty == false, line.hasPrefix("#") == false, line.contains("*") == false else { continue }
            let relative = line.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let source = (root as NSString).appendingPathComponent(relative)
            let destination = (path as NSString).appendingPathComponent(relative)
            guard manager.fileExists(atPath: source), manager.fileExists(atPath: destination) == false else { continue }
            try? manager.createDirectory(atPath: (destination as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try? manager.copyItem(atPath: source, toPath: destination)
        }
    }
}
