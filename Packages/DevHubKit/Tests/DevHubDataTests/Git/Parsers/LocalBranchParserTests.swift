import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct LocalBranchParserTests {
    private static let refs = [
        "main\torigin/main\t\t1000\t/Users/me/App\tkim\tInitial",
        "feature\torigin/feature\t\t3000\t\tsam\tFeature work",
        "old\t\t\t2000\t\t\tOld work",
        "visited\torigin/visited\tahead 1\t500\t\tme\tVisited work\twith a tab",
        "gone\torigin/gone\tgone\t100\t",
        "broken\tline",
    ].joined(separator: "\n")

    private let branches = LocalBranchParser.parse(
        refs,
        merged: ["main", "feature", "visited", "old"],
        visits: ["visited": Date(timeIntervalSince1970: 5000)]
    )

    @Test func sortsByLastVisitedThenCommitDate() {
        #expect(branches.map(\.name) == ["visited", "feature", "old", "main", "gone"])
    }

    @Test func mergedFlagFollowsThePolicy() {
        let merged = Dictionary(uniqueKeysWithValues: branches.map { ($0.name, $0.isMerged) })

        #expect(merged == ["visited": false, "feature": true, "old": false, "main": true, "gone": false])
    }

    @Test func readsTrackingSubjectDateAndWorktree() throws {
        let main = try #require(branches.first { $0.name == "main" })
        let visited = try #require(branches.first { $0.name == "visited" })
        let gone = try #require(branches.first { $0.name == "gone" })

        #expect(main.upstream == "origin/main")
        #expect(main.subject == "Initial")
        #expect(main.commitDate == Date(timeIntervalSince1970: 1000))
        #expect(main.worktreePath == "/Users/me/App")
        #expect(main.author == "kim")
        #expect(visited.subject == "Visited work\twith a tab")
        #expect(gone.author == nil)
        #expect(main.lastVisited == nil)
        #expect(visited.ahead == 1)
        #expect(visited.lastVisited == Date(timeIntervalSince1970: 5000))
        #expect(visited.worktreePath == nil)
        #expect(gone.isGone)
        #expect(gone.subject == "")
    }
}
