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
        #expect(TicketPrefix.prefix(forBranch: branch, ticket: .standard) == prefix)
    }

    @Test(arguments: ["feature/ABC-123", "abc-123", "A-1", "ABC-", "dev"])
    func otherBranchesGetNoPrefix(branch: String) {
        #expect(TicketPrefix.prefix(forBranch: branch, ticket: .standard) == nil)
    }

    @Test(arguments: [
        ("feature/ABC-2324-paid-call", "ABC-2324"),
        ("ABC-2200: Add Follow Top Streamers step", "ABC-2200"),
        ("Draft: ABC-2290: New onboarding", "ABC-2290"),
        ("bugfix/ABC-1881", "ABC-1881"),
    ])
    func keyIsFoundAnywhere(text: String, key: String) {
        #expect(TicketPrefix.key(in: text, ticket: .standard) == key)
    }

    @Test(arguments: ["dev", "release/4.12", "abc-12-lowercase", "T-1"])
    func textWithoutAKeyHasNone(text: String) {
        #expect(TicketPrefix.key(in: text, ticket: .standard) == nil)
    }

    @Test func aConfiguredPatternAndFormatAreUsed() {
        let ticket = TicketSettings(pattern: #"^(?:feature/)?(T-\d+)"#, format: "[$1] ", urlTemplate: "")

        #expect(TicketPrefix.prefix(forBranch: "feature/T-42-login", ticket: ticket) == "[T-42] ")
        #expect(TicketPrefix.key(in: "Fix T-7 crash", ticket: ticket) == "T-7")
        #expect(TicketPrefix.prefix(forBranch: "ABC-1", ticket: ticket) == nil)
    }

    @Test func aBrokenPatternFindsNothing() {
        let ticket = TicketSettings(pattern: "([", format: "$1", urlTemplate: "")

        #expect(TicketPrefix.prefix(forBranch: "ABC-1", ticket: ticket) == nil)
        #expect(TicketPrefix.key(in: "ABC-1", ticket: ticket) == nil)
    }

    @Test func theConfiguredLinkWinsOverTheSettingsLink() {
        var settings = GitSettings.standard
        #expect(settings.ticket(fallbackURL: "https://a.example.com/{key}").urlTemplate == "https://a.example.com/{key}")
        settings.ticketURL = "https://b.example.com/{key}"
        #expect(settings.ticket(fallbackURL: "https://a.example.com/{key}").urlTemplate == "https://b.example.com/{key}")
    }

    @Test func urlNeedsATemplateWithTheKeyPlaceholder() {
        #expect(TicketPrefix.url(forKey: "ABC-1", template: " https://jira.example.com/browse/{key} ") == URL(string: "https://jira.example.com/browse/ABC-1"))
        #expect(TicketPrefix.url(forKey: "ABC-1", template: "") == nil)
        #expect(TicketPrefix.url(forKey: "ABC-1", template: "https://jira.example.com/browse/") == nil)
    }
}
