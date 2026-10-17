import Testing
@testable import DevHubDomain

@Suite struct MergeRequestErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [MergeRequestError] = [.noCodeHost, .notInstalled(tool: "gh"), .notLoggedIn(tool: "glab", host: "gitlab.example.com"), .command("boom")]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func notLoggedInNamesTheToolAndTheHost() {
        #expect(MergeRequestError.notLoggedIn(tool: "glab", host: "gitlab.example.com").errorDescription == "glab is not logged in to gitlab.example.com. Run glab auth login --hostname gitlab.example.com")
    }

    @Test func commandShowsTheMessage() {
        #expect(MergeRequestError.command("boom").errorDescription == "boom")
    }
}
