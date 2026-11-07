import Testing
@testable import DevHubDomain

@Suite struct LogTargetPolicyTests {
    @Test func bootedTargetWins() {
        let target = SimulatorFixture.booted("T")

        let result = LogTargetPolicy.defaultSimulator(target: target, simulators: [SimulatorFixture.booted("A"), target])

        #expect(result == target)
    }

    @Test func shutDownTargetFallsBackToTheFirstBootedSimulator() {
        let result = LogTargetPolicy.defaultSimulator(
            target: SimulatorFixture.shutdown("T"),
            simulators: [SimulatorFixture.shutdown("A"), SimulatorFixture.booted("B"), SimulatorFixture.booted("C")]
        )

        #expect(result?.id == "B")
    }

    @Test func noTargetFallsBackToTheFirstBootedSimulator() {
        let result = LogTargetPolicy.defaultSimulator(target: nil, simulators: [SimulatorFixture.booted("B")])

        #expect(result?.id == "B")
    }

    @Test func nothingBootedGivesNil() {
        let result = LogTargetPolicy.defaultSimulator(target: SimulatorFixture.shutdown("T"), simulators: [SimulatorFixture.shutdown("A")])

        #expect(result == nil)
    }

    @Test func aPhysicalDeviceIsNeverTheLogTarget() {
        let device = SimulatorFixture.device("D")

        #expect(LogTargetPolicy.defaultSimulator(target: device, simulators: [device, SimulatorFixture.booted("B")])?.id == "B")
        #expect(LogTargetPolicy.defaultSimulator(target: nil, simulators: [device]) == nil)
    }
}
