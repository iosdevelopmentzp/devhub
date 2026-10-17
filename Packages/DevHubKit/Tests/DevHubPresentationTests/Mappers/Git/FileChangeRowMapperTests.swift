import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct FileChangeRowMapperTests {
    let checkout = "/Users/dev/Projects/ExampleApp"

    @Test func letterTintAndHintForEveryKind() {
        let table: [(GitChangeKind, String, Tint, String)] = [
            (.modified, "M", .orange, "Modified"),
            (.added, "A", .green, "Added"),
            (.deleted, "D", .red, "Deleted"),
            (.renamed, "R", .blue, "Renamed"),
            (.copied, "C", .blue, "Copied"),
            (.untracked, "?", .green, "New file, not tracked by git yet"),
            (.conflicted, "U", .purple, "Conflict: fix the file, then stage it"),
            (.typeChanged, "T", .orange, "File type changed"),
            (.other("X"), "X", .orange, "Modified")
        ]

        for (kind, letter, tint, hint) in table {
            let model = row(GitFileChange(path: "App/File.swift", originalPath: nil, area: .unstaged, kind: kind), isExpanded: false, isBusy: false)
            #expect(model.letter == letter)
            #expect(model.letterTint == tint)
            #expect(model.letterHint == hint)
        }
    }

    @Test func unstagedChange() {
        let change = GitFileChange(path: "App/Login/LoginView.swift", originalPath: nil, area: .unstaged, kind: .modified)

        let model = row(change, isExpanded: false, isBusy: false)

        #expect(model.id == change.id)
        #expect(model.fileName == "LoginView.swift")
        #expect(model.detail == "App/Login")
        #expect(model.path == "App/Login/LoginView.swift")
        #expect(model.fullPath == "/Users/dev/Projects/ExampleApp/App/Login/LoginView.swift")
        #expect(model.folderPath == "/Users/dev/Projects/ExampleApp/App/Login")
        #expect(model.isStaged == false)
        #expect(model.stageIcon == "plus.circle")
        #expect(model.stageHint == "Stage: include in the next commit")
        #expect(model.discardHint == "Discard the changes in this file")
        #expect(model.discardMessage == "Discard the changes in LoginView.swift? They cannot be restored.")
        #expect(model.discardTitle == "Discard")
        #expect(model.areActionsEnabled)
        #expect(model.diff == nil)
        #expect(model.isExpanded == false)
    }

    @Test func stagedRename() {
        let change = GitFileChange(path: "App/New.swift", originalPath: "App/Old.swift", area: .staged, kind: .renamed)

        let model = row(change, isExpanded: false, isBusy: true)

        #expect(model.detail == "App/Old.swift →")
        #expect(model.isStaged)
        #expect(model.stageIcon == "minus.circle")
        #expect(model.stageHint == "Unstage: keep the change, leave it out of the next commit")
        #expect(model.areActionsEnabled == false)
    }

    @Test func untrackedFileIsDeletedNotDiscarded() {
        let change = GitFileChange(path: "Notes.md", originalPath: nil, area: .untracked, kind: .untracked)

        let model = row(change, isExpanded: false, isBusy: false)

        #expect(model.detail == "")
        #expect(model.stageHint == "Stage: include in the next commit")
        #expect(model.discardHint == "Delete this new file")
        #expect(model.discardMessage == "Delete Notes.md? It was never committed, git cannot bring it back.")
        #expect(model.discardTitle == "Delete")
    }

    @Test func conflictedFileIsMarkedResolvedByStaging() {
        let change = GitFileChange(path: "A.swift", originalPath: nil, area: .conflicted, kind: .conflicted)

        #expect(row(change, isExpanded: false, isBusy: false).stageHint == "Mark as resolved: stage the file")
    }

    @Test func expandedRowCarriesTheDiff() {
        let change = GitFileChange(path: "A.swift", originalPath: nil, area: .unstaged, kind: .modified)

        let loading = row(change, isExpanded: true, isBusy: false)
        let binary = FileChangeRowMapper.model(
            for: change,
            checkoutPath: checkout,
            isExpanded: true,
            diff: GitDiff(lines: [], droppedLines: 0, isBinary: true),
            isBusy: false
        )

        #expect(loading.diff == .loading)
        #expect(loading.isExpanded)
        #expect(binary.diff == .note("Binary file, no text diff"))
    }

    private func row(_ change: GitFileChange, isExpanded: Bool, isBusy: Bool) -> FileChangeRowModel {
        FileChangeRowMapper.model(for: change, checkoutPath: checkout, isExpanded: isExpanded, diff: nil, isBusy: isBusy)
    }
}
