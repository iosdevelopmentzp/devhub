import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIRunParserTests {
    @Test func aListOfRunsDropsTheOnesWithoutAnID() throws {
        let runs = try CircleCIRunParser.runs(from: CircleCIFixture.runs)

        #expect(runs.map(\.id) == [CircleCIFixture.runID, "ffffffff-1111-2222-3333-444444444444"])
        #expect(runs.map(\.status) == [.failed, .running])
        #expect(runs.map(\.branch) == ["feature/ABC-123-short-title", "main"])
        #expect(runs.map(\.revision) == ["aaa111bbb222", "ccc333ddd444"])
        #expect(runs.allSatisfy { $0.createdAt != nil })
    }

    @Test func aPageObjectIsReadToo() throws {
        let runs = try CircleCIRunParser.runs(from: CircleCIFixture.runsPage)

        #expect(runs.map(\.id) == [CircleCIFixture.runID])
        #expect(runs.first?.status == .success)
        #expect(runs.first?.createdAt == nil)
    }

    @Test func anEmptyListIsEmpty() throws {
        #expect(try CircleCIRunParser.runs(from: Data("[]".utf8)).isEmpty)
    }
}
