import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct TabItemMapperTests {
    private let qa = TabConfig(id: "qa", title: "QA", icon: "wrench", searchPrompt: "Search QA tools")

    @Test func customTabsComeAfterTheBuiltInTabs() {
        let items = TabItemMapper.items(customTabs: [qa, TabConfig(id: "ops", title: "Ops")], words: .gitHub)

        #expect(items.count == FeatureRegistry.tabBarFeatures.count + 2)
        #expect(items[items.count - 2] == TabItem(id: .custom("qa"), title: "QA", systemImage: "wrench", searchPrompt: "Search QA tools"))
        #expect(items.last == TabItem(id: .custom("ops"), title: "Ops", systemImage: TabItemMapper.customIcon, searchPrompt: "Search Ops"))
    }

    @Test func aMissingCustomTabFallsBackToHome() {
        #expect(TabItemMapper.item(for: .custom("gone"), customTabs: [qa], words: .gitHub).id == .feature(.home))
        #expect(TabItemMapper.item(for: .custom("qa"), customTabs: [qa], words: .gitHub).searchPrompt == "Search QA tools")
        #expect(TabItemMapper.item(for: .feature(.pullRequests), customTabs: [], words: .gitHub).title == "Pull Requests")
    }
}
