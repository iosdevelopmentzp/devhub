import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ClaudeTranscriptParserTests {
    private let url = URL(fileURLWithPath: "/tmp/projects/-Users-me-App/1F0C5E2A-0000-4000-8000-000000000001.jsonl")
    private let modified = Date(timeIntervalSince1970: 1_767_400_000)

    @Test func readsEveryField() throws {
        let session = try #require(parse([
            ClaudeTranscriptFixture.summary,
            ClaudeTranscriptFixture.user,
            ClaudeTranscriptFixture.secondUser,
            ClaudeTranscriptFixture.aiTitle,
            ClaudeTranscriptFixture.customTitle,
            ClaudeTranscriptFixture.lastPrompt,
        ]))

        #expect(session == AISession(
            id: "1F0C5E2A-0000-4000-8000-000000000001",
            provider: .claude,
            title: "Custom title",
            lastPrompt: "Fix the bug",
            cwd: "/Users/me/Projects/App",
            gitBranch: "feature/x",
            startedAt: Date(timeIntervalSince1970: 1_767_323_045),
            updatedAt: modified,
            folderExists: false
        ))
    }

    @Test func aiTitleWinsOverPrompt() throws {
        let session = try #require(parse([ClaudeTranscriptFixture.user, ClaudeTranscriptFixture.lastPrompt, ClaudeTranscriptFixture.aiTitle]))
        #expect(session.title == "AI title")
    }

    @Test func promptIsTheLastFallback() throws {
        let session = try #require(parse([ClaudeTranscriptFixture.user, ClaudeTranscriptFixture.lastPrompt]))
        #expect(session.title == "Fix the bug")
    }

    @Test func headBranchAndEmptyBranchAreNil() throws {
        let detached = try #require(parse([ClaudeTranscriptFixture.detachedUser, ClaudeTranscriptFixture.aiTitle]))
        let empty = try #require(parse([ClaudeTranscriptFixture.emptyBranchAttachment, ClaudeTranscriptFixture.aiTitle]))

        #expect(detached.gitBranch == nil)
        #expect(empty.gitBranch == nil)
        #expect(empty.startedAt == nil)
    }

    @Test func untypedLineCanCarryTheCwd() throws {
        let session = try #require(parse([ClaudeTranscriptFixture.untypedLine, ClaudeTranscriptFixture.aiTitle]))

        #expect(session.cwd == "/Users/me/Untyped")
        #expect(session.gitBranch == "main")
    }

    @Test func otherTypedLinesDoNotCarryTheCwd() throws {
        let session = try #require(parse([
            ClaudeTranscriptFixture.assistant,
            ClaudeTranscriptFixture.userWithoutCwd,
            ClaudeTranscriptFixture.user,
            ClaudeTranscriptFixture.aiTitle,
        ]))

        #expect(session.cwd == "/Users/me/Projects/App")
    }

    @Test func capsLongTitlesAtThreeHundredCharacters() throws {
        let long = String(repeating: "a", count: 400)
        let session = try #require(parse([ClaudeTranscriptFixture.user, ClaudeTranscriptFixture.lastPrompt(long)]))

        #expect(session.title == String(repeating: "a", count: 300) + "…")
        #expect(session.lastPrompt == session.title)
    }

    @Test func withoutCwdThereIsNoSession() {
        #expect(parse([ClaudeTranscriptFixture.summary, ClaudeTranscriptFixture.aiTitle, ClaudeTranscriptFixture.assistant]) == nil)
    }

    @Test func withoutTitleThereIsNoSession() {
        #expect(parse([ClaudeTranscriptFixture.user]) == nil)
        #expect(parse([ClaudeTranscriptFixture.user, ClaudeTranscriptFixture.lastPrompt("   ")]) == nil)
    }

    @Test func emptyAndBrokenLinesAreSkipped() {
        #expect(parse(["", "{broken", "not json"]) == nil)
    }

    private func parse(_ lines: [String]) -> AISession? {
        ClaudeTranscriptParser.parse(lines: lines, url: url, modified: modified)
    }
}
