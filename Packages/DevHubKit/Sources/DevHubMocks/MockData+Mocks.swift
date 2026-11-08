import Foundation
import DevHubDomain

extension MockData {
    package static let mockSetID = UUID(uuidString: "6F1C2A6E-0B7B-4E43-9C55-6C1F1A0B0001")!
    package static let mockRuleID = UUID(uuidString: "6F1C2A6E-0B7B-4E43-9C55-6C1F1A0B0101")!

    package static let mockRules: [MockRule] = [
        MockRule(
            id: mockRuleID,
            isEnabled: true,
            method: "GET",
            pathPattern: "/v1/settings/list",
            query: nil,
            action: .respond(MockResponse(
                status: 200,
                headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
                body: #"{"data":{"chatEnabled":false,"giftsEnabled":true}}"#,
                delay: 0
            ))
        ),
        MockRule(
            id: UUID(uuidString: "6F1C2A6E-0B7B-4E43-9C55-6C1F1A0B0102")!,
            isEnabled: true,
            method: "GET",
            pathPattern: "/v1/profile/*",
            query: nil,
            action: .patch(MockPatch(
                operations: [
                    JSONPatchOperation(keyPath: "data.profile.isVIP", value: "true"),
                    JSONPatchOperation(keyPath: "data.profile.balance", value: "0")
                ],
                delay: 0.3
            ))
        ),
        MockRule(
            id: UUID(uuidString: "6F1C2A6E-0B7B-4E43-9C55-6C1F1A0B0103")!,
            isEnabled: false,
            method: nil,
            pathPattern: "/v1/gifts/**",
            query: nil,
            action: .respond(MockResponse(status: 503, headers: [], body: #"{"error":{"code":"maintenance"}}"#, delay: 1))
        )
    ]

    package static let mockSets: [MockSet] = [
        MockSet(id: mockSetID, name: "VIP user", rules: mockRules),
        MockSet(id: UUID(uuidString: "6F1C2A6E-0B7B-4E43-9C55-6C1F1A0B0002")!, name: "Empty wallet", rules: [])
    ]

    package static let mockServerExchanges: [NetworkRequest] = [
        NetworkRequest(
            id: 1 << 32,
            method: "GET",
            url: "https://api-qa.example.com/v1/settings/list",
            path: "/v1/settings/list",
            host: "api-qa.example.com",
            statusCode: 200,
            statusText: "OK",
            startedAt: ago(minutes: 0.2),
            duration: 0.004,
            requestBody: "",
            responseBody: #"{"data":{"chatEnabled":false,"giftsEnabled":true}}"#,
            responseHeaders: [HTTPHeader(name: "Content-Type", value: "application/json")],
            error: nil,
            isFailure: false,
            mockRuleID: mockRuleID
        ),
        NetworkRequest(
            id: (1 << 32) + 1,
            method: "GET",
            url: "https://api-qa.example.com/v1/leaderboard/top?period=week",
            path: "/v1/leaderboard/top",
            host: "api-qa.example.com",
            statusCode: 200,
            statusText: "OK",
            startedAt: ago(minutes: 0.1),
            duration: 0.241,
            requestBody: "",
            responseBody: #"{"data":{"items":[]}}"#,
            responseHeaders: [HTTPHeader(name: "Content-Type", value: "application/json")],
            error: nil,
            isFailure: false
        ),
        NetworkRequest(
            id: (1 << 32) + 2,
            method: "GET",
            url: "wss://socket-qa.example.com/socket.io/?EIO=4&transport=websocket",
            path: "/socket.io/",
            host: "socket-qa.example.com",
            statusCode: 101,
            statusText: "Switching Protocols",
            startedAt: ago(minutes: 0.25),
            duration: 12.4,
            requestBody: "",
            responseBody: "→ 40\n← 40{\"sid\":\"abc\"}\n← 42[\"balance\",{\"coins\":120}]",
            responseHeaders: [HTTPHeader(name: "Upgrade", value: "websocket")],
            error: nil,
            isFailure: false,
            requestHeaders: [HTTPHeader(name: "Upgrade", value: "websocket")]
        )
    ]

    package static let sourceScriptExchanges: [NetworkRequest] = [
        NetworkRequest(
            id: 1 << 40,
            method: "GET",
            url: "https://api-qa.example.com/v1/profile/info",
            path: "/v1/profile/info",
            host: "api-qa.example.com",
            statusCode: 200,
            statusText: "no error",
            startedAt: ago(minutes: 0.3),
            duration: 0.182,
            requestBody: "",
            responseBody: #"{"data":{"name":"alex","id":"qa-12"}}"#,
            responseHeaders: [HTTPHeader(name: "Content-Type", value: "application/json")],
            error: nil,
            isFailure: false,
            origin: .sourceScript
        )
    ]
}
