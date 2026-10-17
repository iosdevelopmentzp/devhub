import Testing
@testable import DevHubDomain

@Suite struct MergeRequestErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [MergeRequestError] = [.notGitLab, .notInstalled, .notLoggedIn(host: "gitlab.example.com"), .command("boom")]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func notLoggedInNamesTheHost() {
        #expect(MergeRequestError.notLoggedIn(host: "gitlab.example.com").errorDescription?.contains("gitlab.example.com") == true)
    }

    @Test func commandShowsTheMessage() {
        #expect(MergeRequestError.command("boom").errorDescription == "boom")
    }
}
