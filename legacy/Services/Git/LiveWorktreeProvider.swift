import Foundation

nonisolated struct LiveWorktreeProvider: WorktreeProviding {
    let shell: ShellRunner

    private var git: GitShell { GitShell(shell: shell) }

    func list(at path: String, base: String, settings: WorktreesConfig?) async throws -> [WorktreeInfo] {
        let listed = GitWorktreeParser.parse(try await git.output(["worktree", "list", "--porcelain"], at: path))
        guard let mainPath = listed.first?.path else { return [] }
        let branches = try await git.branches(at: mainPath, base: base)
        return try await withThrowingTaskGroup(of: (Int, WorktreeInfo).self) { group in
            for (index, entry) in listed.enumerated() {
                group.addTask {
                    (index, await info(for: entry, isMain: index == 0, mainPath: mainPath, branches: branches, settings: settings))
                }
            }
            var result: [(Int, WorktreeInfo)] = []
            for try await item in group {
                result.append(item)
            }
            return result.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    func runBootstrap(script: String, at worktree: String) async throws -> Int32 {
        let executable = script.hasPrefix("/") ? script : worktree + "/" + script
        return try await shell.stream(executable, [], cwd: worktree) { _ in }
    }

    func copyIncludes(from main: String, to worktree: String, paths: [String]) async throws -> [String] {
        let outcome: Result<[String], Error> = await offMain {
            Result { try Self.copy(paths, from: main, to: worktree) }
        }
        return try outcome.get()
    }

    private static func copy(_ paths: [String], from main: String, to worktree: String) throws -> [String] {
        let manager = FileManager.default
        var copied: [String] = []
        for relative in paths {
            let source = main + "/" + relative
            let target = worktree + "/" + relative
            guard manager.fileExists(atPath: source), manager.fileExists(atPath: target) == false else { continue }
            try manager.createDirectory(atPath: (target as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try manager.copyItem(atPath: source, toPath: target)
            copied.append(relative)
        }
        return copied
    }

    private func info(for entry: ListedWorktree, isMain: Bool, mainPath: String, branches: BranchSnapshot, settings: WorktreesConfig?) async -> WorktreeInfo {
        var info = WorktreeInfo.sample(path: entry.path, branch: entry.branch, isMain: isMain)
        info.head = entry.head
        info.isLocked = entry.isLocked
        info.isMissing = entry.isPrunable || FileManager.default.fileExists(atPath: entry.path) == false
        if let branch = entry.branch.flatMap({ branches.local(named: $0) }) {
            info.ahead = branch.ahead
            info.behind = branch.behind
            info.hasUpstream = branch.hasUpstream
            info.isMerged = branch.countsAsMerged
            info.isRemoteGone = branch.isUpstreamGone
        } else {
            info.hasUpstream = false
        }
        info.needsBootstrap = isMain == false && info.isMissing == false && Self.needsBootstrap(main: mainPath, worktree: entry.path, settings: settings)
        guard info.isMissing == false else { return info }
        async let status = try? git.status(at: entry.path)
        async let last = git.optionalOutput(["log", "-1", "--format=%ct%x09%s"], at: entry.path)
        info.changeCount = await status?.changeCount ?? 0
        let fields = (await last ?? "").trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t", maxSplits: 1).map(String.init)
        info.lastCommitDate = fields.first.flatMap(TimeParsing.date)
        info.lastCommitSubject = fields.count > 1 ? fields[1] : nil
        return info
    }

    private static func needsBootstrap(main: String, worktree: String, settings: WorktreesConfig?) -> Bool {
        guard let settings, settings.bootstrap != nil, let marker = settings.bootstrapMarker else { return false }
        let manager = FileManager.default
        return manager.fileExists(atPath: main + "/" + marker) && manager.fileExists(atPath: worktree + "/" + marker) == false
    }
}
