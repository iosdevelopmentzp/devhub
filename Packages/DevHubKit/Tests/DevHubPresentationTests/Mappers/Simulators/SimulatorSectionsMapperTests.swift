import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct SimulatorSectionsMapperTests {
    let favoritePhone = Simulator(id: "fav-phone", name: "iPhone 16 Pro", kind: .phone, state: .booted, isFavorite: true)
    let phone = Simulator(id: "phone", name: "iPhone SE", kind: .phone, state: .shutdown, isFavorite: false)
    let favoritePad = Simulator(id: "fav-pad", name: "iPad Air", kind: .pad, state: .shutdown, isFavorite: true)
    let pad = Simulator(id: "pad", name: "iPad mini", kind: .pad, state: .shutdown, isFavorite: false)

    @Test func favoritesComeFirstThenRuntimes() {
        let groups = [
            SimulatorGroup(runtime: "iOS 18.2", simulators: [favoritePhone, phone]),
            SimulatorGroup(runtime: "iOS 17.5", simulators: [pad, favoritePad])
        ]

        let sections = map(groups, matches: { _, _ in true })

        #expect(sections.map(\.id) == ["favorites", "runtime:iOS 18.2", "runtime:iOS 17.5"])
        #expect(sections.map(\.title) == ["Favorites", "iOS 18.2", "iOS 17.5"])
        #expect(sections.map(\.systemImage) == ["star.fill", nil, nil])
        #expect(sections.map(\.detail) == ["2 devices", "1 devices", "1 devices"])
        #expect(sections[0].rows.map(\.id) == ["fav-phone", "fav-pad"])
        #expect(sections[0].rows.map(\.runtimeTag) == [TagModel("iOS 18.2"), TagModel("iOS 17.5")])
        #expect(sections[1].rows.map(\.id) == ["phone"])
        #expect(sections[2].rows.map(\.id) == ["pad"])
    }

    @Test func favoritesFollowTheSavedOrder() {
        let groups = [
            SimulatorGroup(runtime: "iOS 18.2", simulators: [favoritePhone, phone]),
            SimulatorGroup(runtime: "iOS 17.5", simulators: [pad, favoritePad])
        ]

        let sections = map(groups, favoriteOrder: ["fav-pad", "fav-phone"], matches: { _, _ in true })

        #expect(sections[0].rows.map(\.id) == ["fav-pad", "fav-phone"])
    }

    @Test func favoritesMissingFromTheOrderGoLastInListOrder() {
        let groups = [
            SimulatorGroup(runtime: "iOS 18.2", simulators: [favoritePhone, phone]),
            SimulatorGroup(runtime: "iOS 17.5", simulators: [pad, favoritePad])
        ]

        let sections = map(groups, favoriteOrder: ["fav-pad"], matches: { _, _ in true })

        #expect(sections[0].rows.map(\.id) == ["fav-pad", "fav-phone"])
    }

    @Test func withoutFavoritesThereIsNoFavoritesSection() {
        let groups = [SimulatorGroup(runtime: "iOS 18.2", simulators: [phone])]

        #expect(map(groups, matches: { _, _ in true }).map(\.id) == ["runtime:iOS 18.2"])
    }

    @Test func filterDropsRowsAndEmptySections() {
        let groups = [
            SimulatorGroup(runtime: "iOS 18.2", simulators: [favoritePhone, phone]),
            SimulatorGroup(runtime: "iOS 17.5", simulators: [pad, favoritePad])
        ]

        let sections = map(groups, matches: { simulator, _ in simulator.kind == .pad })

        #expect(sections.map(\.id) == ["favorites", "runtime:iOS 17.5"])
        #expect(sections[0].rows.map(\.id) == ["fav-pad"])
        #expect(sections[0].detail == "1 devices")
    }

    @Test func filterReceivesTheRuntime() {
        let groups = [
            SimulatorGroup(runtime: "iOS 18.2", simulators: [phone]),
            SimulatorGroup(runtime: "iOS 17.5", simulators: [pad])
        ]

        #expect(map(groups, matches: { _, runtime in runtime == "iOS 17.5" }).map(\.id) == ["runtime:iOS 17.5"])
    }

    @Test func noGroupsGiveNoSections() {
        #expect(map([], matches: { _, _ in true }).isEmpty)
    }

    private func map(_ groups: [SimulatorGroup], favoriteOrder: [Simulator.ID] = [], matches: (Simulator, String) -> Bool) -> [SimulatorSectionModel] {
        SimulatorSectionsMapper.sections(from: groups, favoriteOrder: favoriteOrder, matches: matches) { simulator, runtime in
            SimulatorRowMapper.model(
                for: simulator,
                runtime: runtime,
                isTarget: false,
                installedApps: nil,
                status: nil,
                identity: nil,
                mockState: nil,
                isUninstalling: false,
                buildIsRunning: false,
                bundleID: "com.example.app",
                isConfirmingErase: false,
                isEditingIdentity: false,
                isMessaging: false,
                configActions: []
            )
        }
    }
}
