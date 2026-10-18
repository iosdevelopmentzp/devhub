import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockWorkspaceOpenerTests {
    @Test func everyActionSucceeds() async {
        let opener = MockWorkspaceOpener()

        #expect(await opener.openTerminal("Terminal", at: "~/App") == nil)
        #expect(await opener.runInTerminal("Terminal", at: "~/App", command: "ls") == nil)
        #expect(await opener.openInEditor("Xcode", path: "~/App") == nil)
        #expect(await opener.openInXcode("~/App", container: nil) == nil)
    }
}
