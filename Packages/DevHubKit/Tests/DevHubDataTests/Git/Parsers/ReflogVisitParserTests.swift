import Foundation
import Testing
@testable import DevHubData

@Suite struct ReflogVisitParserTests {
    @Test func keepsTheLatestVisitPerTarget() {
        let reflog = [
            "checkout: moving from main to feature/x\t2000",
            "checkout: moving from feature/x to main\t3000",
            "checkout: moving from main to feature/x\t1000",
            "commit: Fix to the bug\t4000",
            "checkout: moving from a to b\tnot-a-number",
            "no tab here",
        ].joined(separator: "\n")

        #expect(ReflogVisitParser.parse(reflog) == [
            "feature/x": Date(timeIntervalSince1970: 2000),
            "main": Date(timeIntervalSince1970: 3000),
        ])
    }

    @Test func usesTheLastToInTheMessage() {
        let reflog = "checkout: moving from go to market to release/to-do\t10"

        #expect(ReflogVisitParser.parse(reflog) == ["release/to-do": Date(timeIntervalSince1970: 10)])
    }
}
