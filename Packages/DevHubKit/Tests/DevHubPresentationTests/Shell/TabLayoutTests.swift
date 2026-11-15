import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct TabLayoutTests {
    private let qa = TabConfig(id: "qa", title: "QA", placement: .bar)
    private let ops = TabConfig(id: "ops", title: "Ops")

    @Test func defaultPlacements() {
        let layout = TabLayout()

        #expect(layout.placement(of: .feature(.git), customTabs: []) == .bar)
        #expect(layout.placement(of: .utility(.compressVideo), customTabs: []) == .utils)
        #expect(layout.placement(of: .custom("ops"), customTabs: [qa, ops]) == .utils)
        #expect(layout.placement(of: .custom("qa"), customTabs: [qa, ops]) == .bar)
        #expect(layout.placement(of: .custom("unknown"), customTabs: []) == .utils)
    }

    @Test func homeUtilsNotificationsAndSettingsCannotMove() {
        let layout = TabLayout()

        for tab in [TabID.feature(.home), .feature(.utils), .feature(.notifications), .feature(.settings)] {
            #expect(layout.canMove(tab) == false)
            #expect(layout.moving(tab, to: .utils, customTabs: []) == layout)
            #expect(layout.placement(of: tab, customTabs: []) == .bar)
        }
        #expect(layout.canMove(.feature(.logs)))
        #expect(layout.canMove(.utility(.compressVideo)))
        #expect(layout.canMove(.custom("ops")))
    }

    @Test func aMoveWinsOverTheConfigPlacement() {
        let layout = TabLayout().moving(.custom("qa"), to: .utils, customTabs: []).moving(.custom("ops"), to: .bar, customTabs: [])

        #expect(layout.placement(of: .custom("qa"), customTabs: [qa, ops]) == .utils)
        #expect(layout.placement(of: .custom("ops"), customTabs: [qa, ops]) == .bar)
    }

    @Test func tabsKeepTheRegistryOrderThenUtilitiesThenCustomTabs() {
        let layout = TabLayout().moving(.feature(.network), to: .utils, customTabs: []).moving(.utility(.compressVideo), to: .bar, customTabs: [])

        let bar = layout.tabs(in: .bar, customTabs: [qa, ops])
        let utils = layout.tabs(in: .utils, customTabs: [qa, ops])

        #expect(bar == FeatureRegistry.tabBarFeatures.map { TabID.feature($0.id) }.filter { $0 != .feature(.network) } + [.utility(.compressVideo), .custom("qa")])
        #expect(utils == [.feature(.network), .utility(.tickets), .custom("ops")])
    }

    @Test func aDragPutsTheTabAtTheTargetInBothDirections() {
        let bar = FeatureRegistry.tabBarFeatures.map { TabID.feature($0.id) }
        let right = TabLayout().reordering(.feature(.home), to: .feature(.pullRequests), customTabs: [])
        let left = TabLayout().reordering(.feature(.logs), to: .feature(.home), customTabs: [])

        var expectedRight = bar
        expectedRight.removeAll { $0 == .feature(.home) }
        expectedRight.insert(.feature(.home), at: bar.firstIndex(of: .feature(.pullRequests)) ?? 0)
        #expect(right.tabs(in: .bar, customTabs: []) == expectedRight)
        #expect(left.tabs(in: .bar, customTabs: []).first == .feature(.logs))
        #expect(left.hasCustomOrder)
        #expect(left.tabs(in: .utils, customTabs: []) == [.utility(.compressVideo), .utility(.tickets)])
    }

    @Test func utilsToolsCanBeReorderedAndNewTabsGoLast() {
        let layout = TabLayout().reordering(.utility(.tickets), to: .utility(.compressVideo), customTabs: [ops])

        #expect(layout.tabs(in: .utils, customTabs: [ops]) == [.utility(.tickets), .utility(.compressVideo), .custom("ops")])
        #expect(layout.tabs(in: .utils, customTabs: [ops, TabConfig(id: "new", title: "New")]) == [.utility(.tickets), .utility(.compressVideo), .custom("ops"), .custom("new")])
    }

    @Test func aDropOnATabOfTheOtherBarMovesTheTabThereUnlessItIsFixed() {
        let layout = TabLayout().reordering(.feature(.logs), to: .utility(.tickets), customTabs: [])
        let fixed = TabLayout().reordering(.feature(.home), to: .utility(.tickets), customTabs: [])

        #expect(layout.placement(of: .feature(.logs), customTabs: []) == .utils)
        #expect(layout.tabs(in: .utils, customTabs: []) == [.utility(.compressVideo), .feature(.logs), .utility(.tickets)])
        #expect(layout.tabs(in: .bar, customTabs: []).contains(.feature(.logs)) == false)
        #expect(fixed == TabLayout())
        #expect(TabLayout().reordering(.feature(.git), to: .feature(.git), customTabs: []) == TabLayout())
    }

    @Test func aMoveAfterAReorderPutsTheTabLastInTheOtherBar() {
        let layout = TabLayout()
            .reordering(.utility(.tickets), to: .utility(.compressVideo), customTabs: [])
            .moving(.feature(.logs), to: .utils, customTabs: [])

        #expect(layout.tabs(in: .utils, customTabs: []) == [.utility(.tickets), .utility(.compressVideo), .feature(.logs)])
        #expect(layout.resettingOrder().tabs(in: .utils, customTabs: []) == [.feature(.logs), .utility(.compressVideo), .utility(.tickets)])
        #expect(layout.resettingOrder().hasCustomOrder == false)
    }

    @Test func rawOrderRoundTripsAndSkipsUnknownAndRepeatedValues() {
        let layout = TabLayout().reordering(.feature(.logs), to: .feature(.home), customTabs: [])

        #expect(layout.rawOrder.first == "logs")
        #expect(TabLayout(rawOverrides: [:], rawOrder: layout.rawOrder) == layout)
        #expect(TabLayout(rawOverrides: [:], rawOrder: ["logs", "scripts", "logs", "utility.tickets"]).order == [.feature(.logs), .utility(.tickets)])
    }

    @Test func rawOverridesRoundTripAndSkipUnknownValues() {
        let layout = TabLayout().moving(.feature(.logs), to: .utils, customTabs: []).moving(.custom("ops"), to: .bar, customTabs: [])

        let restored = TabLayout(rawOverrides: layout.rawOverrides, rawOrder: layout.rawOrder)
        let partial = TabLayout(rawOverrides: ["logs": "utils", "scripts": "bar", "git": "sidebar"], rawOrder: [])

        #expect(layout.rawOverrides == ["logs": "utils", "tab.ops": "bar"])
        #expect(restored == layout)
        #expect(partial.overrides == [.feature(.logs): .utils])
    }
}
