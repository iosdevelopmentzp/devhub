import Testing
@testable import DevHubDomain

@Suite struct TargetFallbackPolicyTests {
    @Test func aBootedSimulatorWinsOverAConnectedDevice() {
        let result = TargetFallbackPolicy.target(among: [SimulatorFixture.device("D"), SimulatorFixture.shutdown("A"), SimulatorFixture.booted("B")])

        #expect(result?.id == "B")
    }

    @Test func aShutDownSimulatorWinsOverAConnectedDevice() {
        let result = TargetFallbackPolicy.target(among: [SimulatorFixture.device("D"), SimulatorFixture.shutdown("A")])

        #expect(result?.id == "A")
    }

    @Test func aConnectedDeviceWinsWhenThereIsNoSimulator() {
        let result = TargetFallbackPolicy.target(among: [SimulatorFixture.device("D", connected: false), SimulatorFixture.device("E")])

        #expect(result?.id == "E")
    }

    @Test func nothingGivesNil() {
        #expect(TargetFallbackPolicy.target(among: []) == nil)
    }
}
