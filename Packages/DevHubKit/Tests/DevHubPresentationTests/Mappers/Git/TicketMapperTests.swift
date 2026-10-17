import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketMapperTests {
    @Test func theFirstTextWithAKeyWins() {
        let model = TicketMapper.model(for: ["Fix the crash", "bugfix/ABC-2537", "ABC-1: other"], template: "")

        #expect(model?.key == "ABC-2537")
    }

    @Test func aTemplateMakesALink() {
        let model = TicketMapper.model(for: ["ABC-1: Login"], template: "https://jira.example.com/browse/{key}")

        #expect(model == TicketModel(key: "ABC-1", url: URL(string: "https://jira.example.com/browse/ABC-1"), hint: "Open ABC-1 in the tracker"))
    }

    @Test func withoutATemplateTheChipCopies() {
        let model = TicketMapper.model(for: ["ABC-1: Login"], template: "")

        #expect(model?.url == nil)
        #expect(model?.hint == "Copy ABC-1. Set the ticket link in Settings to open it.")
        #expect(TicketMapper.model(for: ["dev"], template: "x/{key}") == nil)
    }
}
