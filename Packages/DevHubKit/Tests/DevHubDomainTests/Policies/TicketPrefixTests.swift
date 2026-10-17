import Foundation
import Testing
@testable import DevHubDomain

@Suite struct TicketPrefixTests {
    @Test(arguments: [
        ("ABC-123-login-screen", "ABC-123: "),
        ("TL2-7", "TL2-7: "),
        ("IOS-42_fix", "IOS-42: "),
    ])
    func ticketBranchGetsAPrefix(branch: String, prefix: String) {
        #expect(TicketPrefix.prefix(forBranch: branch) == prefix)
    }

    @Test(arguments: ["feature/ABC-123", "abc-123", "A-1", "ABC-", "dev"])
    func otherBranchesGetNoPrefix(branch: String) {
        #expect(TicketPrefix.prefix(forBranch: branch) == nil)
    }

    @Test(arguments: [
        ("feature/ABC-2324-paid-call", "ABC-2324"),
        ("ABC-2200: Add Follow Top Streamers step", "ABC-2200"),
        ("Draft: ABC-2290: New onboarding", "ABC-2290"),
        ("bugfix/ABC-1881", "ABC-1881"),
    ])
    func keyIsFoundAnywhere(text: String, key: String) {
        #expect(TicketPrefix.key(in: text) == key)
    }

    @Test(arguments: ["dev", "release/4.12", "abc-12-lowercase", "T-1"])
    func textWithoutAKeyHasNone(text: String) {
        #expect(TicketPrefix.key(in: text) == nil)
    }

    @Test func urlNeedsATemplateWithTheKeyPlaceholder() {
        #expect(TicketPrefix.url(forKey: "ABC-1", template: " https://jira.example.com/browse/{key} ") == URL(string: "https://jira.example.com/browse/ABC-1"))
        #expect(TicketPrefix.url(forKey: "ABC-1", template: "") == nil)
        #expect(TicketPrefix.url(forKey: "ABC-1", template: "https://jira.example.com/browse/") == nil)
    }
}
