import Testing
@testable import DevHubPresentation

@Suite struct BuildLogTests {
    private func log(appending count: Int) -> BuildLog {
        var log = BuildLog(maxLines: 4, trimSlack: 2)
        for index in 1...count {
            log.append("line \(index)")
        }
        return log
    }

    @Test func keepsEveryLineUpToTheSlack() {
        #expect(log(appending: 6).lines == (1...6).map { "line \($0)" })
    }

    @Test func trimsToTheNewestMaxLinesOncePastTheSlack() {
        #expect(log(appending: 7).lines == (4...7).map { "line \($0)" })
    }

    @Test func removeAllEmptiesTheLog() {
        var log = log(appending: 3)

        log.removeAll()

        #expect(log.lines.isEmpty)
    }
}
