import Foundation
import Testing
@testable import DevHubDomain

@Suite struct NetworkTrafficPolicyTests {
    private func request(_ id: Int, host: String = "api.example.com", at seconds: TimeInterval?, origin: NetworkRequestOrigin = .mockServer) -> NetworkRequest {
        NetworkRequest(id: id, method: "GET", url: "https://\(host)/v1/\(id)", path: "/v1/\(id)", host: host, statusCode: 200, statusText: "", startedAt: seconds.map(Date.init(timeIntervalSince1970:)), duration: nil, requestBody: "", responseBody: "", responseHeaders: [], error: nil, isFailure: false, origin: origin)
    }

    @Test func mergeSortsBothListsByStartTime() {
        let merged = NetworkTrafficPolicy.merge(
            mockServer: [request(1, at: 10), request(2, at: 30)],
            sourceScript: [request(3, at: 20, origin: .sourceScript)],
            isIntercepting: true
        )

        #expect(merged.map(\.id) == [1, 3, 2])
    }

    @Test func loopbackRequestsOfTheScriptAreHiddenWhileTheMockServerRuns() {
        let script = [request(3, host: "127.0.0.1", at: 20, origin: .sourceScript), request(4, at: 25, origin: .sourceScript)]

        #expect(NetworkTrafficPolicy.merge(mockServer: [], sourceScript: script, isIntercepting: true).map(\.id) == [4])
        #expect(NetworkTrafficPolicy.merge(mockServer: [], sourceScript: script, isIntercepting: false).map(\.id) == [3, 4])
    }

    @Test func upsertReplacesTheSameIDAndKeepsTheNewest() {
        var list = NetworkTrafficPolicy.upsert(request(1, at: nil), into: [])
        var changed = request(1, at: nil)
        changed.statusCode = 500
        list = NetworkTrafficPolicy.upsert(changed, into: list)

        #expect(list == [changed])
    }

    @Test func upsertDropsTheOldestOverTheLimit() {
        var list: [NetworkRequest] = []
        for id in 0..<(NetworkTrafficPolicy.maxRequests + 3) {
            list = NetworkTrafficPolicy.upsert(request(id, at: nil), into: list)
        }

        #expect(list.count == NetworkTrafficPolicy.maxRequests)
        #expect(list.first?.id == 3)
    }
}
