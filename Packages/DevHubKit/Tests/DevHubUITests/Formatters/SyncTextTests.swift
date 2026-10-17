import Testing
@testable import DevHubUI

@Suite struct SyncTextTests {
    @Test func aheadAndBehindUseArrows() {
        #expect(SyncText.ahead(2) == "↑2")
        #expect(SyncText.behind(3) == "↓3")
    }

    @Test func textJoinsOnlyNonZeroParts() {
        #expect(SyncText.text(ahead: 0, behind: 0) == "")
        #expect(SyncText.text(ahead: 2, behind: 0) == "↑2")
        #expect(SyncText.text(ahead: 0, behind: 4) == "↓4")
        #expect(SyncText.text(ahead: 2, behind: 4) == "↑2 ↓4")
    }
}
