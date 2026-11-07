import Testing
@testable import DevHubPresentation

@Suite struct SimulatorsToolbarTextTests {
    @Test func countsSimulatorsAndDevicesApart() {
        #expect(SimulatorsToolbarText.count(simulators: [SimulatorFixture.iPhone, SimulatorFixture.iPad]) == "2 simulators")
        #expect(SimulatorsToolbarText.count(simulators: [SimulatorFixture.iPhone, SimulatorFixture.device, SimulatorFixture.offlineDevice]) == "1 simulators · 2 devices")
        #expect(SimulatorsToolbarText.count(simulators: []) == "0 simulators")
    }
}
