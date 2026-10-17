import Foundation
import DevHubDomain

enum MockSetSample {
    static let ruleID = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!

    static let rule = MockRule(
        id: ruleID,
        isEnabled: true,
        method: "GET",
        pathPattern: "/v1/settings/list",
        query: nil,
        action: .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0))
    )

    static let vip = MockSet(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!, name: "VIP", rules: [rule])
    static let empty = MockSet(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!, name: "Empty", rules: [])

    static let qa = URL(string: "https://api-qa.example.com")!
    static let dev = URL(string: "https://api-dev.example.com")!
}
