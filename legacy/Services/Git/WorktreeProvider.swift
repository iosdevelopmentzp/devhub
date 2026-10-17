import Foundation

nonisolated protocol WorktreeProviding: Sendable {
    func list(at path: String, base: String, settings: WorktreesConfig?) async throws -> [WorktreeInfo]
    func derivedData(for paths: [String]) async -> DerivedDataReport
    func removeDerivedData(for path: String) async throws -> Int
    func copyIncludes(from main: String, to worktree: String, paths: [String]) async throws -> [String]
    func runBootstrap(script: String, at worktree: String) async throws -> Int32
}

nonisolated struct MockWorktreeProvider: WorktreeProviding {
    func list(at path: String, base: String, settings: WorktreesConfig?) async throws -> [WorktreeInfo] {
        let now = Date()
        var main = WorktreeInfo.sample(path: path, branch: "main", isMain: true)
        main.changeCount = 3
        main.lastCommitSubject = "Merge pull request"
        main.lastCommitDate = now.addingTimeInterval(-3600)
        var feature = WorktreeInfo.sample(path: path + "-feature", branch: "feature/example")
        feature.ahead = 2
        feature.lastCommitSubject = "Add the example"
        feature.lastCommitDate = now.addingTimeInterval(-86400)
        feature.needsBootstrap = true
        var finished = WorktreeInfo.sample(path: path + "-old", branch: "fix/finished")
        finished.isMerged = true
        finished.lastCommitSubject = "Fix the old thing"
        finished.lastCommitDate = now.addingTimeInterval(-864_000)
        var missing = WorktreeInfo.sample(path: path + "-gone", branch: "fix/missing")
        missing.isMissing = true
        return [main, feature, finished, missing]
    }

    func derivedData(for paths: [String]) async -> DerivedDataReport {
        DerivedDataReport(
            root: "/Users/example/Library/Developer/Xcode/DerivedData",
            totalBytes: 12_400_000_000,
            entries: Dictionary(uniqueKeysWithValues: paths.prefix(2).map { ($0, DerivedDataEntry(folders: [], bytes: 2_100_000_000)) })
        )
    }

    func removeDerivedData(for path: String) async throws -> Int { 1 }

    func copyIncludes(from main: String, to worktree: String, paths: [String]) async throws -> [String] { [] }

    func runBootstrap(script: String, at worktree: String) async throws -> Int32 { 0 }
}
