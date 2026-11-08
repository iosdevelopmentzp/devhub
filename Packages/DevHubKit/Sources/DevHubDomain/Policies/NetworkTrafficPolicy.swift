import Foundation

package enum NetworkTrafficPolicy {
    package static let maxRequests = 2_000

    private static let loopbackHosts: Set<String> = ["127.0.0.1", "localhost", "::1", "[::1]"]

    package static func merge(mockServer: [NetworkRequest], sourceScript: [NetworkRequest], isIntercepting: Bool) -> [NetworkRequest] {
        let fromScript = isIntercepting ? sourceScript.filter { isLoopback($0.host) == false } : sourceScript
        guard fromScript.isEmpty == false else { return mockServer }
        guard mockServer.isEmpty == false else { return fromScript }
        return (mockServer + fromScript).enumerated()
            .sorted { lhs, rhs in
                let left = lhs.element.startedAt ?? .distantPast
                let right = rhs.element.startedAt ?? .distantPast
                return left == right ? lhs.offset < rhs.offset : left < right
            }
            .map(\.element)
    }

    package static func upsert(_ request: NetworkRequest, into list: [NetworkRequest]) -> [NetworkRequest] {
        var list = list
        if let index = list.lastIndex(where: { $0.id == request.id }) {
            list[index] = request
            return list
        }
        list.append(request)
        if list.count > maxRequests {
            list.removeFirst(list.count - maxRequests)
        }
        return list
    }

    package static func isLoopback(_ host: String) -> Bool {
        loopbackHosts.contains(host.lowercased())
    }
}
