import Testing
import DevHubDomain
@testable import DevHubData

@Suite struct SimulatorAppLocationTests {
    private let developerDir = "/Applications/Xcode.app/Contents/Developer"
    private let simulator = "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
    private let deviceHub = "/Applications/Xcode.app/Contents/Applications/DeviceHub.app"

    @Test func xcode26HasSimulatorApp() {
        let location = SimulatorAppLocation.find(developerDir: developerDir) { $0 == simulator }

        #expect(location == .simulator(path: simulator))
        #expect(location.app == .simulator)
    }

    @Test func xcode27HasDeviceHub() {
        let location = SimulatorAppLocation.find(developerDir: developerDir) { $0 == deviceHub }

        #expect(location == .deviceHub(path: deviceHub))
        #expect(location.app == .deviceHub)
    }

    @Test func simulatorAppWinsWhenBothExist() {
        let location = SimulatorAppLocation.find(developerDir: developerDir) { _ in true }

        #expect(location == .simulator(path: simulator))
    }

    @Test func aTrailingSlashInTheDeveloperDirStillFindsDeviceHub() {
        let location = SimulatorAppLocation.find(developerDir: developerDir + "/") { $0 == deviceHub }

        #expect(location == .deviceHub(path: deviceHub))
    }

    @Test func noAppOrNoDeveloperDirIsUnknown() {
        #expect(SimulatorAppLocation.find(developerDir: developerDir) { _ in false } == .unknown)
        #expect(SimulatorAppLocation.find(developerDir: nil) { _ in true } == .unknown)
        #expect(SimulatorAppLocation.find(developerDir: "") { _ in true } == .unknown)
        #expect(SimulatorAppLocation.unknown.app == .simulator)
    }

    @Test func deviceHubURLCarriesTheUDID() {
        #expect(SimulatorAppLocation.deviceHubURL(udid: "A1B2") == "devices://device/open?id=A1B2")
    }
}
