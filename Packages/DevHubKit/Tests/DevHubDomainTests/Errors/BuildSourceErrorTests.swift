import Testing
@testable import DevHubDomain

@Suite struct BuildSourceErrorTests {
    @Test func worktreeErrorsNameTheBranch() {
        let errors: [BuildSourceError] = [.worktreeNotCreated("feature"), .creationFailed(branch: "feature", message: "exit 128")]

        for error in errors {
            #expect(error.errorDescription?.contains("feature") == true)
        }
    }

    @Test func bootstrapFailedShowsTheMessage() {
        let error = BuildSourceError.bootstrapFailed(worktreeName: "feature", path: "/w", createdWorktree: true, message: "bootstrap failed")

        #expect(error.errorDescription == "bootstrap failed")
    }
}
