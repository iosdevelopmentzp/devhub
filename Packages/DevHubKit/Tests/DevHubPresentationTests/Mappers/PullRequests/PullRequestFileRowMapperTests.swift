import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestFileRowMapperTests {
    @Test(arguments: [
        (PullRequestFileDiff.Kind.added, "A", Tint.green, "Added"),
        (.deleted, "D", .red, "Deleted"),
        (.renamed, "R", .blue, "Renamed from Old/a.swift"),
        (.modified, "M", .orange, "Modified"),
    ])
    func kindLetter(kind: PullRequestFileDiff.Kind, letter: String, tint: Tint, hint: String) {
        let model = PullRequestFileRowMapper.model(for: file(kind), review: review(expanded: false, viewed: false, focus: nil), threads: [], words: .gitLab)

        #expect(model.letter == letter)
        #expect(model.letterTint == tint)
        #expect(model.letterHint == hint)
    }

    @Test func collapsedRow() {
        let model = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: nil), threads: [], words: .gitLab)

        #expect(model.id == "App/Login/a.swift")
        #expect(model.fileName == "a.swift")
        #expect(model.detail == "App/Login")
        #expect(model.path == "App/Login/a.swift")
        #expect(model.additionsText == "+4")
        #expect(model.deletionsText == "−2")
        #expect(model.isExpanded == false)
        #expect(model.diff == nil)
        #expect(PullRequestFileRowMapper.model(for: file(.renamed), review: review(expanded: false, viewed: false, focus: nil), threads: [], words: .gitLab).detail == "from Old/a.swift")
    }

    @Test func expandedRowShowsTheDiffOrANote() {
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: nil), threads: [], words: .gitLab).diff == DiffMapper.model(for: file(.modified).diff))
        #expect(
            PullRequestFileRowMapper.model(for: file(.modified, isTooLarge: true), review: review(expanded: true, viewed: false, focus: nil), threads: [], words: .gitLab).diff
                == .note("The diff is too large for GitLab to show. Open the merge request in GitLab.")
        )
    }

    @Test func theFocusedLineIsHighlighted() {
        let focus = DiffFocus(requestID: 7, path: "App/Login/a.swift", line: 1, isOld: false)

        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: focus), threads: [], words: .gitLab).highlightedLineID == 1)
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: focus), threads: [], words: .gitLab).highlightedLineID == nil)
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: DiffFocus(requestID: 7, path: "other", line: 1, isOld: false)), threads: [], words: .gitLab).highlightedLineID == nil)
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: DiffFocus(requestID: 7, path: "App/Login/a.swift", line: 9, isOld: false)), threads: [], words: .gitLab).highlightedLineID == nil)
    }

    @Test func threadsSitUnderTheirLineWhenTheFileIsOpen() {
        let thread = ReviewThreadRowMapper.model(
            for: ReviewThread(id: "t1", noteID: 1, author: "sam", body: "Rename x.\nIt is unclear.", filePath: "App/Login/a.swift", line: 1, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )
        let elsewhere = ReviewThreadRowMapper.model(
            for: ReviewThread(id: "t2", noteID: 2, author: "kim", body: "Other file", filePath: "Other.swift", line: 1, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )

        let open = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, openThreads: ["t1"]), threads: [thread, elsewhere], words: .gitLab)
        let closed = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false), threads: [thread, elsewhere], words: .gitLab)
        let hidden = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, showsThreads: false), threads: [thread], words: .gitLab)

        #expect(open.threadCountText == "1")
        #expect(open.diffThreads.keys.sorted() == [1])
        #expect(open.diffThreads[1]?.map(\.summary) == ["Rename x."])
        #expect(open.diffThreads[1]?.map(\.isOpen) == [true])
        #expect(open.diffThreads[1]?.first?.thread.canShowInDiff == false)
        #expect(closed.diffThreads.isEmpty)
        #expect(closed.threadCountText == "1")
        #expect(hidden.diffThreads.isEmpty)
    }

    @Test func aThreadOnALineOutsideTheDiffStaysOutOfIt() {
        let thread = ReviewThreadRowMapper.model(
            for: ReviewThread(id: "t1", noteID: 1, author: "sam", body: "Old", filePath: "App/Login/a.swift", line: 40, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )

        let model = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true), threads: [thread], words: .gitLab)

        #expect(model.diffThreads.isEmpty)
        #expect(model.threadCountText == "1")
    }

    private func review(
        expanded: Bool,
        viewed: Bool = false,
        focus: DiffFocus? = nil,
        showsThreads: Bool = true,
        openThreads: Set<String> = []
    ) -> PullRequestReviewState {
        PullRequestReviewState(
            expandedFiles: expanded ? ["App/Login/a.swift"] : [],
            viewedFiles: viewed ? ["App/Login/a.swift"] : [],
            focus: focus,
            busyThreads: [],
            showsThreadsInDiff: showsThreads,
            openDiffThreads: openThreads
        )
    }

    private func file(_ kind: PullRequestFileDiff.Kind, isTooLarge: Bool = false) -> PullRequestFileDiff {
        PullRequestFileDiff(
            oldPath: "Old/a.swift",
            path: "App/Login/a.swift",
            kind: kind,
            additions: 4,
            deletions: 2,
            diff: GitDiff(lines: ["@@ -1 +1 @@", "+x"], droppedLines: 0, isBinary: false),
            isTooLarge: isTooLarge
        )
    }

    @Test func aViewedFileSaysSo() {
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: true, focus: nil), threads: [], words: .gitLab).isViewed)
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: nil), threads: [], words: .gitLab).isViewed == false)
    }

    @Test func theLineComposerShowsOnlyOnItsFileAndNeedsText() {
        var state = review(expanded: true)
        state.lineComment = LineCommentDraft(requestID: 7, path: "App/Login/a.swift", oldPath: "Old/a.swift", lineID: 3, newLine: nil, oldLine: 12, text: " ")

        let composer = PullRequestFileRowMapper.lineComposer(review: state, path: "App/Login/a.swift")
        #expect(composer?.lineID == 3)
        #expect(composer?.placeholder == "Comment on removed line 12…")
        #expect(composer?.canSend == false)
        #expect(PullRequestFileRowMapper.lineComposer(review: state, path: "Other.swift") == nil)

        state.lineComment?.text = "Why?"
        #expect(PullRequestFileRowMapper.lineComposer(review: state, path: "App/Login/a.swift")?.canSend == true)
        state.isLineCommentBusy = true
        #expect(PullRequestFileRowMapper.lineComposer(review: state, path: "App/Login/a.swift")?.canSend == false)
        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false), threads: [], words: .gitLab).lineComposer == nil)
    }

    @Test func theWholeFileShowsTheDiffWithTheFileLinesAround() {
        var state = review(expanded: true)
        state.fullFiles = ["App/Login/a.swift"]
        state.fileContents = ["App/Login/a.swift": ["x", "y"]]

        let model = PullRequestFileRowMapper.model(for: file(.modified), review: state, threads: [], words: .gitLab)

        #expect(model.isFull)
        #expect(model.fullHint == "Show only the changed parts")
        #expect(model.diff == DiffMapper.model(for: GitDiff(lines: ["@@ -1,1 +1,2 @@", "+x", " y"], droppedLines: 0, isBinary: false)))
    }

    @Test func theWholeFileWaitsForTheContent() {
        var state = review(expanded: true)
        state.fullFiles = ["App/Login/a.swift"]

        let model = PullRequestFileRowMapper.model(for: file(.modified), review: state, threads: [], words: .gitLab)

        #expect(model.isFull)
        #expect(model.diff == DiffMapper.model(for: file(.modified).diff))
    }

    @Test func hidingSetsTheTagAndTheEyeButton() {
        let model = PullRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false), threads: [], words: .gitLab)

        let visible = PullRequestFileRowMapper.hiding(model, isHidden: false, isChosen: false)
        let chosen = PullRequestFileRowMapper.hiding(model, isHidden: true, isChosen: true)
        let byPattern = PullRequestFileRowMapper.hiding(model, isHidden: true, isChosen: false)

        #expect(visible.canHide)
        #expect(visible.canUnhide == false)
        #expect(visible.hiddenTag == nil)
        #expect(chosen.canHide == false)
        #expect(chosen.canUnhide)
        #expect(chosen.hiddenTag?.hint?.hasPrefix("You hid this file") == true)
        #expect(byPattern.canHide == false)
        #expect(byPattern.canUnhide == false)
        #expect(byPattern.hiddenTag?.hint == "This file matches git.pullRequests.hiddenFiles in project.json")
    }

    @Test func onlyAModifiedOrRenamedTextFileOffersTheWholeFile() {
        let plain = review(expanded: false)

        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: plain, threads: [], words: .gitLab).fullHint == "Show the whole file with the changes in place. DevHub reads the file at the last commit of the merge request from GitLab.")
        #expect(PullRequestFileRowMapper.model(for: file(.renamed), review: plain, threads: [], words: .gitLab).fullHint != nil)
        #expect(PullRequestFileRowMapper.model(for: file(.added), review: plain, threads: [], words: .gitLab).fullHint == nil)
        #expect(PullRequestFileRowMapper.model(for: file(.deleted), review: plain, threads: [], words: .gitLab).fullHint == nil)
        #expect(PullRequestFileRowMapper.model(for: file(.modified, isTooLarge: true), review: plain, threads: [], words: .gitLab).fullHint == nil)
    }

    @Test func everyFileButADeletedOneOpensOnTheWeb() {
        let plain = review(expanded: false)

        #expect(PullRequestFileRowMapper.model(for: file(.modified), review: plain, threads: [], words: .gitLab).canOpenOnWeb)
        #expect(PullRequestFileRowMapper.model(for: file(.added), review: plain, threads: [], words: .gitLab).canOpenOnWeb)
        #expect(PullRequestFileRowMapper.model(for: file(.deleted), review: plain, threads: [], words: .gitLab).canOpenOnWeb == false)
    }
}
