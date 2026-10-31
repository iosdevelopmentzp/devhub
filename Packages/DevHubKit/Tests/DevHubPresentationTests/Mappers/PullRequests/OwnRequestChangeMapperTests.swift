import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct OwnRequestChangeMapperTests {
    private let request = PullRequestSummaryFixture.request(iid: 21, source: "feature/login", state: .opened, author: "me", title: "ABC-5: Login")

    @Test func approvalNamesTheApprovers() throws {
        let one = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex"]), words: .gitLab))
        let two = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex", "sam"]), words: .gitHub))
        let three = try #require(OwnRequestChangeMapper.report(for: .approved(request, by: ["alex", "sam", "lee"]), words: .gitHub))

        #expect(one == OwnRequestChangeMapper.Report(title: "!21 approved by alex", body: "ABC-5: Login", outcome: .success, kind: .requestReviews))
        #expect(two.title == "#21 approved by alex and sam")
        #expect(three.title == "#21 approved by alex, sam and lee")
    }

    @Test func aRequestForChangesNamesTheReviewers() throws {
        let one = try #require(OwnRequestChangeMapper.report(for: .changesRequested(request, by: ["alex"]), words: .gitHub))
        let two = try #require(OwnRequestChangeMapper.report(for: .changesRequested(request, by: ["alex", "sam"]), words: .gitLab))

        #expect(one == OwnRequestChangeMapper.Report(title: "Changes requested on #21 by alex", body: "ABC-5: Login", outcome: .info, kind: .requestReviews))
        #expect(two.title == "Changes requested on !21 by alex and sam")
    }

    @Test func failedChecksUseTheWordsOfTheHost() throws {
        let gitHub = try #require(OwnRequestChangeMapper.report(for: .checksFailed(request), words: .gitHub))
        let gitLab = try #require(OwnRequestChangeMapper.report(for: .checksFailed(request), words: .gitLab))

        #expect(gitHub == OwnRequestChangeMapper.Report(title: "Checks failed on #21", body: "ABC-5: Login", outcome: .failure, kind: .requestChecks))
        #expect(gitLab.title == "Pipeline failed on !21")
    }

    @Test func commentsAreCounted() throws {
        let one = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 1, by: []), words: .gitHub))
        let three = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 3, by: []), words: .gitHub))
        let sam = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 1, by: ["sam"]), words: .gitHub))
        let many = try #require(OwnRequestChangeMapper.report(for: .newComments(request, count: 3, by: ["sam", "lee"]), words: .gitLab))

        #expect(one == OwnRequestChangeMapper.Report(title: "1 new comment on #21", body: "ABC-5: Login", outcome: .info, kind: .requestComments))
        #expect(three.title == "3 new comments on #21")
        #expect(sam == OwnRequestChangeMapper.Report(title: "sam commented on #21", body: "ABC-5: Login", outcome: .info, kind: .requestComments))
        #expect(many.title == "sam and lee commented on !21 (3 new comments)")
    }

    @Test func aGoneRequestNeedsItsFinalState() throws {
        #expect(OwnRequestChangeMapper.report(for: .gone(request), words: .gitHub) == nil)
        #expect(OwnRequestChangeMapper.report(forGone: request, state: .opened, words: .gitHub) == nil)
        #expect(OwnRequestChangeMapper.report(forGone: request, state: .locked, words: .gitHub) == nil)

        let merged = try #require(OwnRequestChangeMapper.report(forGone: request, state: .merged, words: .gitHub))
        let closed = try #require(OwnRequestChangeMapper.report(forGone: request, state: .closed, words: .gitLab))

        #expect(merged == OwnRequestChangeMapper.Report(title: "#21 merged", body: "ABC-5: Login", outcome: .success, kind: .requestClosed))
        #expect(closed == OwnRequestChangeMapper.Report(title: "!21 closed without a merge", body: "ABC-5: Login", outcome: .info, kind: .requestClosed))
    }
}
