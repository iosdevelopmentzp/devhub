import Testing
@testable import DevHubDomain

@Suite struct NotificationKindTests {
    @Test func onlyScriptsShowWhileThePanelIsOpen() {
        #expect(NotificationKind.allCases.filter(\.showsWhilePanelIsOpen) == [.scripts])
    }

    @Test func rawValuesAreStable() {
        #expect(NotificationKind.allCases.map(\.rawValue) == ["build", "tests", "reviewRequests", "requestReviews", "requestChecks", "requestComments", "requestClosed", "watched", "inbox", "scripts"])
    }
}
