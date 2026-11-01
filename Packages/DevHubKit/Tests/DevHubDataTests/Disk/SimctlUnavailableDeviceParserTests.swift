import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct SimctlUnavailableDeviceParserTests {
    @Test func unavailableDevicesBecomeOneItemWithTheirTotalSize() throws {
        let item = try #require(try SimctlUnavailableDeviceParser.item(from: Data(DiskCleanupFixture.unavailableDevices.utf8)))

        #expect(item.id == "unavailableSimulators")
        #expect(item.kind == .unavailableSimulators)
        #expect(item.count == 2)
        #expect(item.size == 1500)
        #expect(item.paths.count == 2)
    }

    @Test func noUnavailableDevicesGiveNoItem() throws {
        #expect(try SimctlUnavailableDeviceParser.item(from: Data(DiskCleanupFixture.noUnavailableDevices.utf8)) == nil)
    }

    @Test func aBrokenAnswerThrows() {
        #expect(throws: DiskCleanupError.self) {
            try SimctlUnavailableDeviceParser.item(from: Data("[]".utf8))
        }
    }
}
