import Foundation
import DevHubDomain
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct TicketMapperTests {
    @Test func theFirstTextWithAKeyWins() {
        let model = TicketMapper.model(for: ["Fix the crash", "bugfix/ABC-2537", "ABC-1: other"], ticket: .standard)

        #expect(model?.key == "ABC-2537")
    }

    @Test func aTemplateMakesALink() {
        let model = TicketMapper.model(for: ["ABC-1: Login"], ticket: .linking("https://jira.example.com/browse/{key}"))

        #expect(model == TicketModel(key: "ABC-1", url: URL(string: "https://jira.example.com/browse/ABC-1"), hint: "Open ABC-1 in the tracker"))
    }

    @Test func withoutATemplateTheChipCopies() {
        let model = TicketMapper.model(for: ["ABC-1: Login"], ticket: .standard)

        #expect(model?.url == nil)
        #expect(model?.hint == "Copy ABC-1. Set git.ticketURL in .devhub/project.json or the ticket link in Settings to open it.")
        #expect(TicketMapper.model(for: ["dev"], ticket: .linking("x/{key}")) == nil)
    }
}
