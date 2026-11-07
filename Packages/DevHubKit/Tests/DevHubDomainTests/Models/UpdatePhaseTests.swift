import Testing
@testable import DevHubDomain

@Suite struct UpdatePhaseTests {
    @Test func titlesAndRunningFlag() {
        #expect(UpdatePhase.allCases.map(\.title) == ["Getting changes", "Building", "Installing", "Done", "Failed"])
        #expect(UpdatePhase.allCases.map(\.isRunning) == [true, true, true, false, false])
    }
}
