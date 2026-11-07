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
            #expect(layout.moving(tab, to: .utils) == layout)
            #expect(layout.placement(of: tab, customTabs: []) == .bar)
        }
        #expect(layout.canMove(.feature(.logs)))
        #expect(layout.canMove(.utility(.compressVideo)))
        #expect(layout.canMove(.custom("ops")))
    }

    @Test func aMoveWinsOverTheConfigPlacement() {
        let layout = TabLayout().moving(.custom("qa"), to: .utils).moving(.custom("ops"), to: .bar)

        #expect(layout.placement(of: .custom("qa"), customTabs: [qa, ops]) == .utils)
        #expect(layout.placement(of: .custom("ops"), customTabs: [qa, ops]) == .bar)
    }

    @Test func tabsKeepTheRegistryOrderThenUtilitiesThenCustomTabs() {
        let layout = TabLayout().moving(.feature(.network), to: .utils).moving(.utility(.compressVideo), to: .bar)

        let bar = layout.tabs(in: .bar, customTabs: [qa, ops])
        let utils = layout.tabs(in: .utils, customTabs: [qa, ops])

        #expect(bar == FeatureRegistry.tabBarFeatures.map { TabID.feature($0.id) }.filter { $0 != .feature(.network) } + [.utility(.compressVideo), .custom("qa")])
        #expect(utils == [.feature(.network), .utility(.tickets), .custom("ops")])
    }

    @Test func rawOverridesRoundTripAndSkipUnknownValues() {
        let layout = TabLayout().moving(.feature(.logs), to: .utils).moving(.custom("ops"), to: .bar)

        let restored = TabLayout(rawOverrides: layout.rawOverrides)
        let partial = TabLayout(rawOverrides: ["logs": "utils", "scripts": "bar", "git": "sidebar"])

        #expect(layout.rawOverrides == ["logs": "utils", "tab.ops": "bar"])
        #expect(restored == layout)
        #expect(partial.overrides == [.feature(.logs): .utils])
    }
}
