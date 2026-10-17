import Testing
@testable import DevHubDomain

@Suite struct DeviceIdentityErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [DeviceIdentityError] = [.command("simctl failed"), .noAppToReinstall]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func commandShowsTheMessage() {
        #expect(DeviceIdentityError.command("simctl failed").errorDescription == "simctl failed")
    }
}
