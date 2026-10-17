import Foundation
import DevHubDomain

struct MockHTTPRequest: Equatable, Sendable {
    var method: String
    var target: String
    var version: String
    var headers: [HTTPHeader]
    var body: Data

    var path: String {
        String(target.prefix { $0 != "?" })
    }

    var query: String? {
        guard let mark = target.firstIndex(of: "?") else { return nil }
        return String(target[target.index(after: mark)...])
    }

    var isWebSocketUpgrade: Bool {
        header("Upgrade")?.lowercased() == "websocket"
    }

    func header(_ name: String) -> String? {
        headers.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}
