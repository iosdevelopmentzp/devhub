import Testing
@testable import DevHubDomain

@Suite struct CIErrorTests {
    @Test func everyCaseTellsWhatToDo() {
        #expect(CIError.notInstalled.errorDescription?.contains("brew install circleci") == true)
        #expect(CIError.oldVersion(found: "0.1.3").errorDescription?.contains("0.1.3") == true)
        #expect(CIError.oldVersion(found: "0.1.3").errorDescription?.contains("brew upgrade circleci") == true)
        #expect(CIError.notLoggedIn.errorDescription?.contains("circleci auth login") == true)
        #expect(CIError.command("boom").errorDescription == "boom")
    }
}
