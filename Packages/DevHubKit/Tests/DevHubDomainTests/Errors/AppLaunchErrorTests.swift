import Testing
@testable import DevHubDomain

@Suite struct AppLaunchErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [AppLaunchError] = [.command("simctl failed"), .noAppToReinstall]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func commandShowsTheMessage() {
        #expect(AppLaunchError.command("simctl failed").errorDescription == "simctl failed")
    }
}
