import Testing
@testable import DevHubDomain

@Suite struct SimulatorErrorTests {
    @Test func everyCaseHasADescription() {
        let errors: [SimulatorError] = [.command("Unable to boot"), .malformedList]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test func commandShowsTheMessage() {
        #expect(SimulatorError.command("Unable to boot").errorDescription == "Unable to boot")
    }
}
