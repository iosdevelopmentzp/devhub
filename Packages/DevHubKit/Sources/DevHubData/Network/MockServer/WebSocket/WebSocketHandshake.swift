import Foundation
import DevHubDomain

enum WebSocketHandshake {
    struct ResponseHead: Equatable {
        var status: Int
        var reason: String
        var headers: [HTTPHeader]
        var length: Int
    }

    static let maxHeadSize = 64 * 1024

    private static let droppedHeaders: Set<String> = ["host", "origin", "sec-websocket-extensions", "content-length", "proxy-connection", "proxy-authorization"]
    private static let headEnd = Data("\r\n\r\n".utf8)

    static func endpoint(for upstream: URL) -> (host: String, port: Int, isSecure: Bool)? {
        guard let host = upstream.host, host.isEmpty == false else { return nil }
        let isSecure = upstream.scheme?.lowercased() == "https"
        return (host, upstream.port ?? (isSecure ? 443 : 80), isSecure)
    }

    static func webSocketURL(upstream: URL, target: String) -> String {
        guard let url = HTTPForwarder.url(upstream: upstream, target: target), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return target
        }
        components.scheme = upstream.scheme?.lowercased() == "https" ? "wss" : "ws"
        return components.string ?? target
    }

    static func requestHead(for request: MockHTTPRequest, upstream: URL) -> Data? {
        guard let url = HTTPForwarder.url(upstream: upstream, target: request.target),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let endpoint = endpoint(for: upstream) else { return nil }
        var target = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        if let query = components.percentEncodedQuery {
            target += "?" + query
        }
        let isDefaultPort = endpoint.port == (endpoint.isSecure ? 443 : 80)
        let host = isDefaultPort ? endpoint.host : "\(endpoint.host):\(endpoint.port)"
        var lines = ["\(request.method) \(target) HTTP/1.1", "Host: \(host)"]
        if request.header("Origin") != nil {
            lines.append("Origin: \(endpoint.isSecure ? "https" : "http")://\(host)")
        }
        for header in request.headers where droppedHeaders.contains(header.name.lowercased()) == false {
            lines.append("\(header.name): \(header.value)")
        }
        return Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
    }

    static func responseHead(in data: Data) -> ResponseHead? {
        guard let end = data.range(of: headEnd),
              let head = String(data: data[data.startIndex..<end.lowerBound], encoding: .utf8) else { return nil }
        let lines = head.components(separatedBy: "\r\n")
        let parts = lines[0].split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2, parts[0].hasPrefix("HTTP/"), let status = Int(parts[1]) else { return nil }
        let headers = lines.dropFirst().compactMap { line -> HTTPHeader? in
            guard let colon = line.firstIndex(of: ":") else { return nil }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces)
            guard name.isEmpty == false else { return nil }
            return HTTPHeader(name: name, value: line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces))
        }
        return ResponseHead(
            status: status,
            reason: parts.count > 2 ? String(parts[2]) : "",
            headers: headers,
            length: data.distance(from: data.startIndex, to: end.upperBound)
        )
    }
}
