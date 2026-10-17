import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct SimctlListParserTests {
    private let groups: [SimulatorGroup]

    init() throws {
        groups = try SimctlListParser.parse(SimctlListFixture.json)
    }

    @Test func ordersRuntimesNewestFirstAndDropsOthers() {
        #expect(groups.map(\.runtime) == ["iOS 26.0", "iOS 18.2", "iOS 17.5"])
    }

    @Test func ordersPhonesBeforePadsThenByName() throws {
        let group = try #require(groups.first { $0.runtime == "iOS 18.2" })

        #expect(group.simulators.map(\.id) == ["B4", "B3", "B2", "B1", "B6"])
    }

    @Test func dropsUnavailableDevices() {
        let ids = groups.flatMap(\.simulators).map(\.id)

        #expect(ids.contains("B5") == false)
        #expect(ids.contains("D1") == false)
        #expect(ids.contains("W1") == false)
    }

    @Test func mapsStates() throws {
        let simulators = Dictionary(uniqueKeysWithValues: groups.flatMap(\.simulators).map { ($0.id, $0.state) })

        #expect(simulators["B1"] == .booted)
        #expect(simulators["B2"] == .booting)
        #expect(simulators["B3"] == .shuttingDown)
        #expect(simulators["B4"] == .shutdown)
        #expect(simulators["A1"] == .shutdown)
    }

    @Test func detectsPadsByIdentifierOrName() {
        let kinds = Dictionary(uniqueKeysWithValues: groups.flatMap(\.simulators).map { ($0.id, $0.kind) })

        #expect(kinds["B1"] == .pad)
        #expect(kinds["B6"] == .pad)
        #expect(kinds["B2"] == .phone)
    }

    @Test func trimsNamesAndClearsFavorites() throws {
        let simulator = try #require(groups.first?.simulators.first)

        #expect(simulator.name == "iPhone 17")
        #expect(groups.flatMap(\.simulators).allSatisfy { $0.isFavorite == false })
    }

    @Test(arguments: [SimctlListFixture.malformed, Data("not json".utf8)])
    func malformedListThrows(data: Data) {
        let error = #expect(throws: SimulatorError.self) {
            try SimctlListParser.parse(data)
        }
        guard case .malformedList? = error else {
            Issue.record("Expected .malformedList, got \(String(describing: error))")
            return
        }
    }
}
