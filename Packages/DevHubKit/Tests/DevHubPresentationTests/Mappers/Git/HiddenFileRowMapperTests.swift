import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct HiddenFileRowMapperTests {
    private let checkout = "/Users/dev/example-app"

    private func row(_ file: GitHiddenFile, isExpanded: Bool = false, diff: GitDiff? = nil) -> HiddenFileRowModel {
        HiddenFileRowMapper.model(for: file, checkoutPath: checkout, isExpanded: isExpanded, diff: diff, isBusy: false, syntaxColors: false)
    }

    @Test func aChangedFileShowsItsStateAndFlags() {
        let model = row(GitHiddenFile(path: "Config/Local.xcconfig", flags: [.assumeUnchanged, .skipWorktree], state: .modified))

        #expect(model.letter == "M")
        #expect(model.letterTint == .orange)
        #expect(model.flags.map(\.text) == ["skip-worktree", "assume-unchanged"])
        #expect(model.hasChanges)
        #expect(model.revealPath == "/Users/dev/example-app/Config/Local.xcconfig")
        #expect(model.canOpen)
    }

    @Test func aDeletedFileShowsItsFolderAndCannotOpen() {
        let model = row(GitHiddenFile(path: "Config/Local.xcconfig", flags: [.skipWorktree], state: .deleted))

        #expect(model.letter == "D")
        #expect(model.letterTint == .red)
        #expect(model.revealPath == "/Users/dev/example-app/Config")
        #expect(model.canOpen == false)
    }

    @Test func anUnchangedFileHasANoteAndNothingToStash() {
        let model = row(GitHiddenFile(path: "a.plist", flags: [.assumeUnchanged], state: .unchanged), isExpanded: true)

        #expect(model.letter == "=")
        #expect(model.hasChanges == false)
        #expect(model.diff == .note("No hidden changes: the file is the same as in git."))
        #expect(model.diffText == nil)
    }

    @Test func anExpandedChangedFileCarriesItsDiffText() {
        let diff = GitDiff(lines: ["@@ -1 +1 @@", "-a", "+b"], droppedLines: 0, isBinary: false)

        let model = row(GitHiddenFile(path: "a.txt", flags: [.skipWorktree], state: .modified), isExpanded: true, diff: diff)

        #expect(model.isExpanded)
        #expect(model.diffText == "@@ -1 +1 @@\n-a\n+b")
    }
}
