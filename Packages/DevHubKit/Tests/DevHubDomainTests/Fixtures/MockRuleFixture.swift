import Foundation
@testable import DevHubDomain

enum MockRuleFixture {
    static let settingsID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let profileID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static func respond(method: String?, path: String) -> MockRule {
        rule(id: UUID(), method: method, path: path, query: nil, isEnabled: true)
    }

    static func rule(id: UUID, method: String?, path: String, query: String?, isEnabled: Bool) -> MockRule {
        MockRule(
            id: id,
            isEnabled: isEnabled,
            method: method,
            pathPattern: path,
            query: query,
            action: .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0))
        )
    }

    static let set = MockSet(
        id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
        name: "VIP",
        rules: [rule(id: settingsID, method: "GET", path: "/v1/settings/list", query: nil, isEnabled: true)]
    )
}
