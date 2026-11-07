import Testing
@testable import DevHubDomain

@Suite struct NotificationKindTests {
    @Test func onlyScriptsShowWhileThePanelIsOpen() {
        #expect(NotificationKind.allCases.filter(\.showsWhilePanelIsOpen) == [.scripts])
    }

    @Test func rawValuesAreStable() {
        #expect(NotificationKind.allCases.map(\.rawValue) == ["build", "tests", "reviewRequests", "reviewReminders", "requestReviews", "requestChecks", "requestChecksPassed", "requestApprovals", "baseBranchChecks", "requestComments", "requestClosed", "watched", "inbox", "crashes", "scripts", "utilities"])
    }
}
