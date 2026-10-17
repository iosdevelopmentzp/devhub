import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestThreadRowMapperTests {
    @Test func threadOnALine() {
        let model = PullRequestThreadRowMapper.model(
            for: PullRequestThread(id: "1", noteID: 11, author: "sam", body: "Move", filePath: "App/Login.swift", line: 12, isOnOldLine: false, replies: [PullRequestNote(author: "me", body: "Done"), PullRequestNote(author: "sam", body: "Thanks")]),
            diffs: [login],
            webURL: webURL,
            isBusy: false
        )

        #expect(model == PullRequestThreadRowModel(
            id: "1",
            author: "sam",
            location: "Login.swift:12",
            locationHint: "App/Login.swift:12",
            body: "Move",
            repliesText: "2 replies",
            replies: [PullRequestNoteModel(id: 0, author: "me", body: "Done"), PullRequestNoteModel(id: 1, author: "sam", body: "Thanks")],
            filePath: "App/Login.swift",
            line: 12,
            isOnOldLine: false,
            canShowInDiff: true,
            noteURL: URL(string: "https://gitlab.example.com/team/app/-/merge_requests/7#note_11"),
            isBusy: false
        ))
    }

    @Test func generalThreadWithOneReply() {
        let model = PullRequestThreadRowMapper.model(
            for: PullRequestThread(id: "1", noteID: nil, author: "sam", body: "Move", filePath: nil, line: nil, isOnOldLine: false, replies: [PullRequestNote(author: "me", body: "Done")]),
            diffs: [login],
            webURL: webURL,
            isBusy: false
        )

        #expect(model.location == nil)
        #expect(model.locationHint == nil)
        #expect(model.repliesText == "1 reply")
        #expect(model.noteURL == nil)
        #expect(model.canShowInDiff == false)
    }

    @Test func fileWithoutLineAndNoReplies() {
        let model = PullRequestThreadRowMapper.model(
            for: PullRequestThread(id: "1", noteID: nil, author: "sam", body: "Move", filePath: "App/Login.swift", line: nil, isOnOldLine: false, replies: []),
            diffs: [login],
            webURL: webURL,
            isBusy: false
        )

        #expect(model.location == "Login.swift")
        #expect(model.repliesText == nil)
        #expect(model.canShowInDiff == false)
    }

    @Test func aFileOutsideTheDiffCannotBeShown() {
        let model = PullRequestThreadRowMapper.model(
            for: PullRequestThread(id: "1", noteID: nil, author: "sam", body: "Move", filePath: "App/Old.swift", line: 3, isOnOldLine: false, replies: []),
            diffs: [login],
            webURL: webURL,
            isBusy: false
        )

        #expect(model.canShowInDiff == false)
    }

    @Test func aLineOutsideTheDiffCannotBeShown() {
        let model = PullRequestThreadRowMapper.model(
            for: PullRequestThread(id: "1", noteID: nil, author: "sam", body: "Move", filePath: "App/Login.swift", line: 99, isOnOldLine: false, replies: []),
            diffs: [login],
            webURL: webURL,
            isBusy: false
        )

        #expect(model.canShowInDiff == false)
    }

    private let webURL = URL(string: "https://gitlab.example.com/team/app/-/merge_requests/7")

    private let login = PullRequestFileDiff(
        oldPath: "App/Login.swift",
        path: "App/Login.swift",
        kind: .modified,
        additions: 1,
        deletions: 0,
        diff: GitDiff(lines: ["@@ -10,2 +10,3 @@", " a", " b", "+c"], droppedLines: 0, isBinary: false),
        isTooLarge: false
    )
}
