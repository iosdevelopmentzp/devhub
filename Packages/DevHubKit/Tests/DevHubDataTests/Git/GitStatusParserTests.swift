import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitStatusParserTests {
    private let changes = GitStatusParser.parse(GitStatusFixture.porcelain)

    @Test func parsesEveryRecordInOrder() {
        #expect(changes == [
            GitFileChange(path: "staged.swift", originalPath: nil, area: .staged, kind: .modified),
            GitFileChange(path: "unstaged.swift", originalPath: nil, area: .unstaged, kind: .modified),
            GitFileChange(path: "both.swift", originalPath: nil, area: .staged, kind: .modified),
            GitFileChange(path: "both.swift", originalPath: nil, area: .unstaged, kind: .modified),
            GitFileChange(path: "added.swift", originalPath: nil, area: .staged, kind: .added),
            GitFileChange(path: "removed.swift", originalPath: nil, area: .unstaged, kind: .deleted),
            GitFileChange(path: "renamed.swift", originalPath: "old name.swift", area: .staged, kind: .renamed),
            GitFileChange(path: "copy.swift", originalPath: "source.swift", area: .staged, kind: .copied),
            GitFileChange(path: "moved.swift", originalPath: "origin.swift", area: .staged, kind: .renamed),
            GitFileChange(path: "moved.swift", originalPath: nil, area: .unstaged, kind: .modified),
            GitFileChange(path: "type.swift", originalPath: nil, area: .staged, kind: .typeChanged),
            GitFileChange(path: "weird.swift", originalPath: nil, area: .staged, kind: .other("X")),
            GitFileChange(path: "new folder/file.txt", originalPath: nil, area: .untracked, kind: .untracked),
            GitFileChange(path: "conflict.swift", originalPath: nil, area: .conflicted, kind: .conflicted),
            GitFileChange(path: "both-added.swift", originalPath: nil, area: .conflicted, kind: .conflicted),
            GitFileChange(path: "both-deleted.swift", originalPath: nil, area: .conflicted, kind: .conflicted),
            GitFileChange(path: "added-by-us.swift", originalPath: nil, area: .conflicted, kind: .conflicted),
            GitFileChange(path: "deleted-by-them.swift", originalPath: nil, area: .conflicted, kind: .conflicted),
        ])
    }

    @Test func emptyOutputHasNoChanges() {
        #expect(GitStatusParser.parse("").isEmpty)
    }

    @Test func skipsRecordsTooShortToHoldAPath() {
        #expect(GitStatusParser.parse("M \0?? a\0") == [
            GitFileChange(path: "a", originalPath: nil, area: .untracked, kind: .untracked),
        ])
    }
}
