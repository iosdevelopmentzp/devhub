import Testing
@testable import DevHubData

@Suite struct MockRouteNameTests {

    @Test func fileNameFollowsTheUITestFixtureNaming() {
        #expect(MockRouteName.fileName(method: "get", path: "/v1/settings/list") == "GET_v1_settings_list.json")
        #expect(MockRouteName.fileName(method: nil, path: "/v1/gifts/**") == "ANY_v1_gifts___.json")
    }

    @Test func stemKeepsSafeCharactersOnly() {
        #expect(MockRouteName.stem(for: " VIP user / empty ") == "VIP-user-empty")
        #expect(MockRouteName.stem(for: "///") == "set")
    }
}
