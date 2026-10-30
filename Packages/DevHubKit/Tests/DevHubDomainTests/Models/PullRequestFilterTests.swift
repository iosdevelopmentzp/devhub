import Foundation
import Testing
@testable import DevHubDomain

@Suite struct PullRequestFilterTests {

    @Test func toggleLabelAddsThenRemoves() {
        var filter = PullRequestFilter()

        filter.toggleLabel("tech")
        filter.toggleLabel("bug")
        #expect(filter.labels == ["tech", "bug"])

        filter.toggleLabel("tech")
        #expect(filter.labels == ["bug"])
    }

    @Test func aSavedFilterRoundTrips() throws {
        let filter = PullRequestFilter(targetBranch: "dev", labels: ["tech", "bug"], author: "alex", assignee: "sam", reviewer: "kim", onlyConflicts: true, onlyReady: false)

        let data = try JSONEncoder().encode(filter)

        #expect(try JSONDecoder().decode(PullRequestFilter.self, from: data) == filter)
    }

    @Test func anOldSavedFilterWithOneLabelStillLoads() throws {
        let old = Data(#"{"label":"tech","onlyConflicts":true}"#.utf8)

        #expect(try JSONDecoder().decode(PullRequestFilter.self, from: old) == PullRequestFilter(labels: ["tech"], onlyConflicts: true))
    }

    @Test func missingKeysMeanNoFilter() throws {
        #expect(try JSONDecoder().decode(PullRequestFilter.self, from: Data("{}".utf8)) == PullRequestFilter())
    }
}
