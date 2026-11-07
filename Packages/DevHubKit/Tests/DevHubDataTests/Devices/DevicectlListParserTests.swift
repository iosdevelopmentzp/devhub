import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct DevicectlListParserTests {
    private let devices: [Simulator]

    init() throws {
        devices = try DevicectlListParser.parse(DevicectlListFixture.json)
    }

    @Test func keepsPhonesAndPadsConnectedFirstThenByName() {
        #expect(devices.map(\.id) == ["00008110-000000000000001C", "00008110-000000000000001B", "00008110-000000000000001A"])
        #expect(devices.allSatisfy { $0.isPhysical })
        #expect(devices.allSatisfy { $0.isFavorite == false })
    }

    @Test func mapsNamesKindsStatesAndRuntimes() throws {
        let phone = try #require(devices.first { $0.id == "00008110-000000000000001B" })
        let offline = try #require(devices.first { $0.id == "00008110-000000000000001A" })
        let pad = try #require(devices.first { $0.id == "00008110-000000000000001C" })

        #expect(phone.name == "Sam's iPhone")
        #expect(phone.kind == .phone)
        #expect(phone.state == .booted)
        #expect(phone.runtime == "iOS 27.0.1")
        #expect(offline.state == .shutdown)
        #expect(offline.runtime == "iOS 18.6.2")
        #expect(pad.name == "iPad Air")
        #expect(pad.kind == .pad)
    }

    @Test func dropsWatchesSimulatorsAndRecordsWithoutHardware() {
        let ids = devices.map(\.id)

        #expect(ids.contains("00008301-000000000000001D") == false)
        #expect(ids.contains("SIM-1") == false)
        #expect(ids.contains("no-hardware") == false)
    }

    @Test(arguments: [DevicectlListFixture.malformed, Data("not json".utf8)])
    func malformedListThrows(data: Data) {
        let error = #expect(throws: DeviceError.self) {
            try DevicectlListParser.parse(data)
        }
        guard case .malformedList? = error else {
            Issue.record("Expected .malformedList, got \(String(describing: error))")
            return
        }
    }
}
