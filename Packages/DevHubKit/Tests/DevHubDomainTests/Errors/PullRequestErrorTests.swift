import Testing
@testable import DevHubDomain

@Suite struct PullRequestErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [PullRequestError] = [.noCodeHost, .notInstalled(tool: "gh"), .notLoggedIn(tool: "glab", host: "gitlab.example.com"), .command("boom")]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func notLoggedInNamesTheToolAndTheHost() {
        #expect(PullRequestError.notLoggedIn(tool: "glab", host: "gitlab.example.com").errorDescription == "glab is not logged in to gitlab.example.com. Run glab auth login --hostname gitlab.example.com")
    }

    @Test func commandShowsTheMessage() {
        #expect(PullRequestError.command("boom").errorDescription == "boom")
    }
}
