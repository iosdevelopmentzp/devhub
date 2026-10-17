import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct TrackingInfoParserTests {
    @Test func readsAheadAndBehind() {
        let tracking = TrackingInfoParser.tracking(upstream: "origin/feature", track: "ahead 2, behind 13")

        #expect(tracking.upstream == "origin/feature")
        #expect(tracking.ahead == 2)
        #expect(tracking.behind == 13)
        #expect(tracking.isGone == false)
    }

    @Test func emptyUpstreamBecomesNil() {
        let tracking = TrackingInfoParser.tracking(upstream: "", track: "")

        #expect(tracking.upstream == nil)
        #expect(tracking.ahead == 0)
        #expect(tracking.behind == 0)
        #expect(tracking.isGone == false)
    }

    @Test func goneTrack() {
        let tracking = TrackingInfoParser.tracking(upstream: "origin/old", track: "gone")

        #expect(tracking.isGone)
        #expect(tracking.ahead == 0)
    }

    @Test func parsesTabSeparatedLinesAndSkipsOthers() throws {
        let output = "main\torigin/main\tbehind 4\nfeature\t\t\nbroken line\nlocal\torigin/local\tahead 1\textra\n"

        let result = TrackingInfoParser.parse(output)

        #expect(Set(result.keys) == ["main", "feature"])
        let main = try #require(result["main"])
        #expect(main.upstream == "origin/main")
        #expect(main.behind == 4)
        #expect(result["feature"]?.upstream == nil)
    }

    @Test(arguments: [
        ("ahead ", "ahead 12, behind 1", 12),
        ("behind ", "ahead 12, behind 1", 1),
        ("behind ", "ahead 12", 0),
        ("ahead ", "ahead x", 0),
    ])
    func countAfterLabel(label: String, track: String, expected: Int) {
        #expect(TrackingInfoParser.count(after: label, in: track) == expected)
    }
}
