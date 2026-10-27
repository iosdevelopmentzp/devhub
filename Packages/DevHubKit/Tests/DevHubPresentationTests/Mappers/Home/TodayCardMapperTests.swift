import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TodayCardMapperTests {
    private func failed(_ iid: Int, author: String) -> PullRequestSummary {
        PullRequestSummaryFixture.request(iid: iid, source: "b\(iid)", state: .opened, author: author, pipeline: PipelineInfo(status: .failed, webURL: nil, updatedAt: nil), title: "ABC-\(iid): Login")
    }

    private var finished: Worktree {
        var worktree = WorktreeFixture.linked
        worktree.isMerged = true
        return worktree
    }

    @Test func everyFactGivesOneItemInAFixedOrder() {
        let items = TodayCardMapper.items(
            reviewCount: 2,
            openRequests: [failed(12, author: "alex"), failed(13, author: "sam")],
            username: "alex",
            worktrees: [WorktreeFixture.main, finished],
            simulators: [SimulatorFixture.iPhone, SimulatorFixture.iPad],
            words: .gitHub
        )

        #expect(items.map(\.id) == ["review", "failed", "worktrees", "simulators"])
        #expect(items[0].title == "2 pull requests wait for your review")
        #expect(items[0].target == .pullRequests(.reviewing))
        #expect(items[1].title == "#12 ABC-12: Login")
        #expect(items[1].target == .pullRequest(12))
        #expect(items[2].title == "1 finished worktree can be cleaned up")
        #expect(items[3].title == "1 simulator booted")
        #expect(items[3].detail == "iPhone 16 Pro")
    }

    @Test func severalFailedRequestsOpenTheMineScope() {
        let items = TodayCardMapper.items(reviewCount: 0, openRequests: [failed(12, author: "alex"), failed(14, author: "alex")], username: "alex", worktrees: [], simulators: [], words: .gitLab)

        #expect(items.map(\.target) == [.pullRequests(.mine)])
        #expect(items[0].title == "2 of your merge requests: pipeline failed")
        #expect(items[0].detail == "!14, !12")
    }

    @Test func nothingToDoGivesNoItems() {
        #expect(TodayCardMapper.items(reviewCount: 0, openRequests: [], username: nil, worktrees: [WorktreeFixture.main], simulators: [SimulatorFixture.iPad], words: .gitHub).isEmpty)
    }
}
