import Testing
@testable import DevHubDomain

@Suite struct XcodeAttachErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [XcodeAttachError] = [.accessibilityNotGranted, .noProject("/repo"), .xcodeDidNotOpen, .script("boom"), .stillStopped(42)]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func stillStoppedNamesThePID() {
        #expect(XcodeAttachError.stillStopped(4242).errorDescription?.contains("4242") == true)
    }

    @Test func scriptShowsTheMessage() {
        #expect(XcodeAttachError.script("boom").errorDescription == "Xcode attach failed: boom")
    }
}
