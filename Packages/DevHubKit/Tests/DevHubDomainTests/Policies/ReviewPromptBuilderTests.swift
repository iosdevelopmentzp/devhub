import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ReviewPromptBuilderTests {
    private let request = PullRequestSummaryFixture.open

    @Test func everyThreadBecomesABlockWithItsPlaceAuthorAndReplies() {
        let threads = [
            PullRequestThread(id: "d1", noteID: 1, author: "lee", body: "Rename this.\nIt reads badly.", filePath: "App/Login.swift", line: 42, isOnOldLine: false, replies: [PullRequestNote(author: "alex", body: "To what?")]),
            PullRequestThread(id: "d2", noteID: 2, author: "kim", body: "Why was this removed?", filePath: "App/Old.swift", line: 7, isOnOldLine: true, replies: []),
            PullRequestThread(id: "d3", noteID: 3, author: "sam", body: "Add a test.", filePath: nil, line: nil, isOnOldLine: false, replies: []),
        ]

        let prompt = ReviewPromptBuilder.prompt(for: request, threads: threads)

        #expect(prompt.hasPrefix("# Review threads of !21: ABC-5: Login\n"))
        #expect(prompt.contains("Branch `feature/login` into `dev`. Review page: https://gitlab.example.com/team/app/-/merge_requests/21"))
        #expect(prompt.contains("Reviewers left 3 open threads."))
        #expect(prompt.contains("## Thread 1: `App/Login.swift:42`\n\n**lee**:\n\n> Rename this.\n> It reads badly.\n\n**alex** replied:\n\n> To what?\n"))
        #expect(prompt.contains("## Thread 2: `App/Old.swift:7` (a removed line)"))
        #expect(prompt.contains("## Thread 3 (general comment)"))
        #expect(prompt.contains("## What to do"))
        #expect(prompt.hasSuffix("as replies in the review.\n"))
    }

    @Test func oneThreadIsSingular() {
        let thread = PullRequestThread(id: "d1", noteID: 1, author: "lee", body: "Fix", filePath: "a.swift", line: nil, isOnOldLine: false, replies: [])

        let prompt = ReviewPromptBuilder.prompt(for: request, threads: [thread])

        #expect(prompt.contains("Reviewers left 1 open thread."))
        #expect(prompt.contains("## Thread 1: `a.swift`\n"))
    }

    @Test func commandReadsTheQuotedPromptFile() {
        #expect(ReviewPromptBuilder.command(promptPath: "/Users/me/.devhub/prompts/mr-21.md") == "claude \"$(cat '/Users/me/.devhub/prompts/mr-21.md')\"")
    }
}
