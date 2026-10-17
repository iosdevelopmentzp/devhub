import Foundation
import DevHubDomain

struct HTTPForwarder: Sendable {
    let session: URLSession

    static let droppedRequestHeaders: Set<String> = [
        "host", "connection", "accept-encoding", "content-length", "keep-alive", "proxy-connection",
        "proxy-authorization", "te", "trailer", "transfer-encoding", "upgrade"
    ]
    static let droppedResponseHeaders: Set<String> = [
        "connection", "keep-alive", "proxy-authenticate", "te", "trailer", "transfer-encoding", "upgrade",
        "content-encoding", "content-length"
    ]
    static let timeout: TimeInterval = 60

    func forward(_ request: MockHTTPRequest, to upstream: URL) async throws -> MockHTTPResponse {
        guard let urlRequest = Self.urlRequest(for: request, upstream: upstream) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(for: urlRequest, delegate: NoRedirectDelegate())
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return MockHTTPResponse(status: http.statusCode, headers: Self.responseHeaders(of: http), body: data)
    }

    static func url(upstream: URL, target: String) -> URL? {
        var base = upstream.absoluteString
        while base.hasSuffix("/") {
            base.removeLast()
        }
        return URL(string: base + (target.hasPrefix("/") ? target : "/" + target))
    }

    static func urlRequest(for request: MockHTTPRequest, upstream: URL) -> URLRequest? {
        guard let url = url(upstream: upstream, target: request.target) else { return nil }
        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout)
        urlRequest.httpMethod = request.method
        urlRequest.httpShouldHandleCookies = false
        for header in request.headers where droppedRequestHeaders.contains(header.name.lowercased()) == false {
            urlRequest.addValue(header.value, forHTTPHeaderField: header.name)
        }
        urlRequest.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        urlRequest.httpBody = request.body.isEmpty ? nil : request.body
        return urlRequest
    }

    static func responseHeaders(of response: HTTPURLResponse) -> [HTTPHeader] {
        response.allHeaderFields
            .compactMap { key, value -> HTTPHeader? in
                guard let name = key as? String else { return nil }
                return HTTPHeader(name: name, value: "\(value)")
            }
            .filter { droppedResponseHeaders.contains($0.name.lowercased()) == false }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}

private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
