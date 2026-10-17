import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestFileRowMapperTests {
    @Test(arguments: [
        (MergeRequestFileDiff.Kind.added, "A", Tint.green, "Added"),
        (.deleted, "D", .red, "Deleted"),
        (.renamed, "R", .blue, "Renamed from Old/a.swift"),
        (.modified, "M", .orange, "Modified"),
    ])
    func kindLetter(kind: MergeRequestFileDiff.Kind, letter: String, tint: Tint, hint: String) {
        let model = MergeRequestFileRowMapper.model(for: file(kind), review: review(expanded: false, viewed: false, focus: nil), threads: [])

        #expect(model.letter == letter)
        #expect(model.letterTint == tint)
        #expect(model.letterHint == hint)
    }

    @Test func collapsedRow() {
        let model = MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: nil), threads: [])

        #expect(model.id == "App/Login/a.swift")
        #expect(model.fileName == "a.swift")
        #expect(model.detail == "App/Login")
        #expect(model.path == "App/Login/a.swift")
        #expect(model.additionsText == "+4")
        #expect(model.deletionsText == "−2")
        #expect(model.isExpanded == false)
        #expect(model.diff == nil)
        #expect(MergeRequestFileRowMapper.model(for: file(.renamed), review: review(expanded: false, viewed: false, focus: nil), threads: []).detail == "from Old/a.swift")
    }

    @Test func expandedRowShowsTheDiffOrANote() {
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: nil), threads: []).diff == DiffMapper.model(for: file(.modified).diff))
        #expect(
            MergeRequestFileRowMapper.model(for: file(.modified, isTooLarge: true), review: review(expanded: true, viewed: false, focus: nil), threads: []).diff
                == .note("The diff is too large for GitLab to show. Open the merge request in GitLab.")
        )
    }

    @Test func theFocusedLineIsHighlighted() {
        let focus = DiffFocus(requestID: 7, path: "App/Login/a.swift", line: 1, isOld: false)

        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: focus), threads: []).highlightedLineID == 1)
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: focus), threads: []).highlightedLineID == nil)
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: DiffFocus(requestID: 7, path: "other", line: 1, isOld: false)), threads: []).highlightedLineID == nil)
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, viewed: false, focus: DiffFocus(requestID: 7, path: "App/Login/a.swift", line: 9, isOld: false)), threads: []).highlightedLineID == nil)
    }

    @Test func threadsSitUnderTheirLineWhenTheFileIsOpen() {
        let thread = MergeRequestThreadRowMapper.model(
            for: MergeRequestThread(id: "t1", noteID: 1, author: "sam", body: "Rename x.\nIt is unclear.", filePath: "App/Login/a.swift", line: 1, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )
        let elsewhere = MergeRequestThreadRowMapper.model(
            for: MergeRequestThread(id: "t2", noteID: 2, author: "kim", body: "Other file", filePath: "Other.swift", line: 1, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )

        let open = MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, openThreads: ["t1"]), threads: [thread, elsewhere])
        let closed = MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false), threads: [thread, elsewhere])
        let hidden = MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true, showsThreads: false), threads: [thread])

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
        let thread = MergeRequestThreadRowMapper.model(
            for: MergeRequestThread(id: "t1", noteID: 1, author: "sam", body: "Old", filePath: "App/Login/a.swift", line: 40, isOnOldLine: false, replies: []),
            diffs: [],
            webURL: nil,
            isBusy: false
        )

        let model = MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: true), threads: [thread])

        #expect(model.diffThreads.isEmpty)
        #expect(model.threadCountText == "1")
    }

    private func review(
        expanded: Bool,
        viewed: Bool = false,
        focus: DiffFocus? = nil,
        showsThreads: Bool = true,
        openThreads: Set<String> = []
    ) -> MergeRequestReviewState {
        MergeRequestReviewState(
            expandedFiles: expanded ? ["App/Login/a.swift"] : [],
            viewedFiles: viewed ? ["App/Login/a.swift"] : [],
            focus: focus,
            busyThreads: [],
            showsThreadsInDiff: showsThreads,
            openDiffThreads: openThreads
        )
    }

    private func file(_ kind: MergeRequestFileDiff.Kind, isTooLarge: Bool = false) -> MergeRequestFileDiff {
        MergeRequestFileDiff(
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
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: true, focus: nil), threads: []).isViewed)
        #expect(MergeRequestFileRowMapper.model(for: file(.modified), review: review(expanded: false, viewed: false, focus: nil), threads: []).isViewed == false)
    }
}
