import Testing
@testable import DevHubPresentation

@Suite struct FeatureRegistryTests {
    @Test func everyFeatureIDResolvesToItsFeature() {
        for id in FeatureID.allCases {
            #expect(FeatureRegistry.feature(id).id == id)
        }
        #expect(FeatureRegistry.all.map(\.id) == FeatureID.allCases)
    }

    @Test func defaultFeatureIsHome() {
        #expect(FeatureRegistry.defaultFeatureID == .home)
    }

    @Test func settingsIsHiddenFromTheTabBarAndHasNoSearch() {
        let settings = FeatureRegistry.feature(.settings)

        #expect(settings.showsInTabBar == false)
        #expect(settings.searchPrompt == nil)
        #expect(FeatureRegistry.tabBarFeatures.map(\.id) == FeatureID.allCases.filter { $0 != .settings && $0 != .notifications })
    }

    @Test func everyTabHasTitleIconAndSearchPrompt() {
        for feature in FeatureRegistry.tabBarFeatures {
            #expect(feature.title.isEmpty == false)
            #expect(feature.systemImage.isEmpty == false)
            #expect(feature.searchPrompt?.isEmpty == false || feature.id == .utils)
        }
    }

    @Test func utilsTakesItsSearchPromptFromTheSubTab() {
        #expect(FeatureRegistry.feature(.utils).searchPrompt == nil)
    }
}
