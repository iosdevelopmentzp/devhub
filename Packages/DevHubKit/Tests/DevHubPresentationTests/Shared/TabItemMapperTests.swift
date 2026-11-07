import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct TabItemMapperTests {
    private let qa = TabConfig(id: "qa", title: "QA", icon: "wrench", searchPrompt: "Search QA tools", placement: .bar)
    private let ops = TabConfig(id: "ops", title: "Ops")

    @Test func theBarHoldsTheBuiltInTabsThenTheCustomTabsPlacedThere() {
        let items = TabItemMapper.items(in: .bar, layout: TabLayout(), customTabs: [qa, ops], words: .gitHub)

        #expect(items.count == FeatureRegistry.tabBarFeatures.count + 1)
        #expect(items.first?.id == .feature(.home))
        #expect(items.last == TabItem(id: .custom("qa"), title: "QA", systemImage: "wrench", searchPrompt: "Search QA tools"))
    }

    @Test func utilsHoldsTheUtilitiesThenTheOtherCustomTabs() {
        let items = TabItemMapper.items(in: .utils, layout: TabLayout(), customTabs: [qa, ops], words: .gitHub)

        #expect(items.map(\.id) == [.utility(.compressVideo), .utility(.tickets), .custom("ops")])
        #expect(items.first == TabItem(id: .utility(.compressVideo), title: "Compress Video", systemImage: "film", searchPrompt: "Filter videos"))
        #expect(items.last == TabItem(id: .custom("ops"), title: "Ops", systemImage: TabItemMapper.customIcon, searchPrompt: "Search Ops"))
    }

    @Test func theLayoutMovesTabsBetweenTheBarAndUtils() {
        let layout = TabLayout().moving(.feature(.logs), to: .utils).moving(.utility(.compressVideo), to: .bar)

        let bar = TabItemMapper.items(in: .bar, layout: layout, customTabs: [], words: .gitHub).map(\.id)
        let utils = TabItemMapper.items(in: .utils, layout: layout, customTabs: [], words: .gitHub).map(\.id)

        #expect(bar.contains(.feature(.logs)) == false)
        #expect(bar.last == .utility(.compressVideo))
        #expect(utils == [.feature(.logs), .utility(.tickets)])
    }

    @Test func allItemsListTheBarThenUtils() {
        let all = TabItemMapper.allItems(layout: TabLayout(), customTabs: [ops], words: .gitHub).map(\.id)

        #expect(all.suffix(3) == [.utility(.compressVideo), .utility(.tickets), .custom("ops")])
        #expect(all.count == FeatureRegistry.tabBarFeatures.count + 3)
    }

    @Test func aMissingCustomTabFallsBackToHome() {
        #expect(TabItemMapper.item(for: .custom("gone"), customTabs: [qa], words: .gitHub).id == .feature(.home))
        #expect(TabItemMapper.item(for: .custom("qa"), customTabs: [qa], words: .gitHub).searchPrompt == "Search QA tools")
        #expect(TabItemMapper.item(for: .feature(.pullRequests), customTabs: [], words: .gitHub).title == "Pull Requests")
        #expect(TabItemMapper.item(for: .utility(.compressVideo), customTabs: [], words: .gitHub).title == "Compress Video")
    }
}
