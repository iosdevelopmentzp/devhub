import Testing
@testable import DevHubDomain

@Suite struct BuildErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [BuildError] = [.noXcodeContainer("/repo"), .failed("boom"), .appNotFound]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func failedShowsTheMessage() {
        #expect(BuildError.failed("Build failed: 3 errors").errorDescription == "Build failed: 3 errors")
    }

    @Test func noXcodeContainerNamesThePath() {
        #expect(BuildError.noXcodeContainer("/repo").errorDescription?.contains("/repo") == true)
    }
}
