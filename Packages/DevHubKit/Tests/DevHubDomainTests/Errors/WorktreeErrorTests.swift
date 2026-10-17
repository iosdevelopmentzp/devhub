import Testing
@testable import DevHubDomain

@Suite struct WorktreeErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [WorktreeError] = [.notARepository("/tmp/x"), .command("fatal"), .invalidBranchName]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func notARepositoryNamesThePath() {
        #expect(WorktreeError.notARepository("/tmp/x").errorDescription?.contains("/tmp/x") == true)
    }
}
