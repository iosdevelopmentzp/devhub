import Foundation
import Testing
@testable import DevHubData

@Suite struct JobLogTailTests {
    @Test func keepsTheLastLinesWithoutTimestampsAndColors() {
        let text = (1...5).map { "2026-10-17T22:42:17.8508807Z \u{1B}[36mline \($0)\u{1B}[0m" }.joined(separator: "\n") + "\n"

        #expect(JobLogTail.text(from: Data(text.utf8), limit: 2) == "line 4\nline 5")
    }

    @Test func hidesTokens() {
        let text = JobLogTail.text(from: Data("token=abc123secret\nok".utf8))

        #expect(text.contains("abc123secret") == false)
        #expect(text.hasSuffix("ok"))
    }
}
