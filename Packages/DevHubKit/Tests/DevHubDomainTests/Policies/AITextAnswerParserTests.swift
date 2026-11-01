import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AITextAnswerParserTests {
    @Test func cleanRemovesFencesColorsAndBlankEdges() {
        #expect(AITextAnswerParser.clean("\n\n```\nfeat: add calls\n```\n\n") == "feat: add calls")
        #expect(AITextAnswerParser.clean("\u{1B}[1mfix: crash\u{1B}[0m") == "fix: crash")
        #expect(AITextAnswerParser.clean("feat: x\n\nBody line") == "feat: x\n\nBody line")
    }

    @Test func titleAndBodySplitAtTheFirstLine() {
        let parts = AITextAnswerParser.titleAndBody("ABC-123: Paid calls\n\n## What changes\n- A")

        #expect(parts.title == "ABC-123: Paid calls")
        #expect(parts.body == "## What changes\n- A")
    }

    @Test func titleLabelsAndQuotesAreRemoved() {
        let parts = AITextAnswerParser.titleAndBody("Title: \"ABC-123: Paid calls\"\nDescription:\nAdds calls.")

        #expect(parts.title == "ABC-123: Paid calls")
        #expect(parts.body == "Adds calls.")
        #expect(AITextAnswerParser.titleAndBody("# Paid calls").title == "Paid calls")
    }

    @Test func anEmptyAnswerGivesEmptyParts() {
        let parts = AITextAnswerParser.titleAndBody("  \n ")

        #expect(parts.title.isEmpty)
        #expect(parts.body.isEmpty)
    }
}
