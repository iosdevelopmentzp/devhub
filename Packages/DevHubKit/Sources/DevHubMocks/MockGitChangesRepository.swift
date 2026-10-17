import Foundation
import DevHubDomain

struct MockGitChangesRepository: GitChangesRepository {

    func changes(in path: String) async throws -> [GitFileChange] {
        [
            GitFileChange(path: "ExampleApp/Features/Call/CallPromptView.swift", originalPath: nil, area: .staged, kind: .modified),
            GitFileChange(path: "ExampleApp/Features/Call/CallPromptViewModel.swift", originalPath: nil, area: .unstaged, kind: .modified),
            GitFileChange(path: "ExampleApp/Resources/en.lproj/Localizable.strings", originalPath: nil, area: .unstaged, kind: .modified),
            GitFileChange(path: "ExampleApp/Features/Call/GiftValue.swift", originalPath: nil, area: .untracked, kind: .untracked)
        ]
    }

    func diff(for change: GitFileChange, in path: String) async throws -> GitDiff {
        GitDiff(
            lines: [
                "diff --git a/\(change.path) b/\(change.path)",
                "@@ -12,7 +12,8 @@ struct CallPromptView: View {",
                "     let gift: Gift",
                "-    let value: Int",
                "+    let value: GiftValue",
                "+    let onFailure: (Error) -> Void",
                "     var body: some View {"
            ],
            droppedLines: 0,
            isBinary: false
        )
    }

    func branchCommits(base: String, in path: String) async throws -> [GitCommit] {
        [
            GitCommit(hash: "0362516c73ac02ae16961be5dce11137392a397a", shortHash: "0362516c7", author: "Alex", date: Date().addingTimeInterval(-7_200), subject: "ABC-2489: Reset a Leaderboard follow status", isPushed: false)
        ]
    }

    func commitFiles(hash: String, in path: String) async throws -> [GitCommitFile] {
        [
            GitCommitFile(path: "ExampleApp/Features/Call/CallPromptView.swift", originalPath: nil, kind: .modified),
            GitCommitFile(path: "ExampleApp/Features/Call/GiftValue.swift", originalPath: nil, kind: .added)
        ]
    }

    func commitDiff(hash: String, file: GitCommitFile, in path: String) async throws -> GitDiff {
        try await diff(for: GitFileChange(path: file.path, originalPath: nil, area: .staged, kind: file.kind), in: path)
    }

    func reflog(in path: String) async throws -> [GitReflogEntry] {
        let now = Date()
        return [
            GitReflogEntry(index: 0, hash: "0362516c73ac02ae16961be5dce11137392a397a", shortHash: "0362516c7", date: now.addingTimeInterval(-600), action: "commit", message: "ABC-2489: Reset a Leaderboard follow status"),
            GitReflogEntry(index: 1, hash: "cf17ab4f1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", shortHash: "cf17ab4f1", date: now.addingTimeInterval(-3_600), action: "checkout", message: "moving from dev to ABC-2489-leaderboardFollowStatusReset"),
            GitReflogEntry(index: 2, hash: "cf17ab4f1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", shortHash: "cf17ab4f1", date: now.addingTimeInterval(-7_200), action: "pull", message: "Fast-forward")
        ]
    }
}
