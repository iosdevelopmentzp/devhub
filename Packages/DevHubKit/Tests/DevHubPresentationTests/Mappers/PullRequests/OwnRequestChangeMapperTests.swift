import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct OwnRequestChangeMapperTests {
    private let request = PullRequestSummaryFixture.request(iid: 21, source: "feature/login", state: .opened, author: "me", title: "ABC-5: Login")

    @Test func approvalNamesTheApprovers() throws {
        let one = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex"]), words: .gitLab))
        let two = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex", "sam"]), words: .gitHub))
        let three = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex", "sam", "lee"]), words: .gitHub))

        #expect(one == OwnRequestChangeMapper.Report(title: "!21 approved by alex", body: "ABC-5: Login", outcome: .success))
        #expect(two.title == "#21 approved by alex and sam")
        #expect(three.title == "#21 approved by alex, sam and lee")
    }

    @Test func failedChecksUseTheWordsOfTheHost() throws {
        let gitHub = try #require(OwnRequestChangeMapper.report(for: .checksFailed(request), words: .gitHub))
        let gitLab = try #require(OwnRequestChangeMapper.report(for: .checksFailed(request), words: .gitLab))

        #expect(gitHub == OwnRequestChangeMapper.Report(title: "Checks failed on #21", body: "ABC-5: Login", outcome: .failure))
        #expect(gitLab.title == "Pipeline failed on !21")
    }

    @Test func commentsAreCounted() throws {
        let one = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 1), words: .gitHub))
        let three = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 3), words: .gitHub))

        #expect(one == OwnRequestChangeMapper.Report(title: "1 new comment on #21", body: "ABC-5: Login", outcome: .info))
        #expect(three.title == "3 new comments on #21")
    }

    @Test func aGoneRequestNeedsItsFinalState() throws {
        #expect(OwnRequestChangeMapper.report(for: .gone(request), words: .gitHub) == nil)
        #expect(OwnRequestChangeMapper.report(forGone: request, state: .opened, words: .gitHub) == nil)
        #expect(OwnRequestChangeMapper.report(forGone: request, state: .locked, words: .gitHub) == nil)

        let merged = try #require(OwnRequestChangeMapper.report(forGone: request, state: .merged, words: .gitHub))
        let closed = try #require(OwnRequestChangeMapper.report(forGone: request, state: .closed, words: .gitLab))

        #expect(merged == OwnRequestChangeMapper.Report(title: "#21 merged", body: "ABC-5: Login", outcome: .success))
        #expect(closed == OwnRequestChangeMapper.Report(title: "!21 closed without a merge", body: "ABC-5: Login", outcome: .info))
    }
}
