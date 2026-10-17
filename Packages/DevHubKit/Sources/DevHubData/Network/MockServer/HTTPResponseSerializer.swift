import Foundation
import DevHubDomain

enum HTTPResponseSerializer {
    private static let managedHeaders: Set<String> = ["content-length", "connection", "transfer-encoding"]

    static func data(for response: MockHTTPResponse) -> Data {
        var lines = ["HTTP/1.1 \(response.status) \(reasonPhrase(response.status))"]
        lines += response.headers
            .filter { managedHeaders.contains($0.name.lowercased()) == false }
            .map { "\($0.name): \(sanitized($0.value))" }
        lines.append("Content-Length: \(response.body.count)")
        lines.append("Connection: close")
        var data = Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
        data.append(response.body)
        return data
    }

    static func reasonPhrase(_ status: Int) -> String {
        switch status {
        case 200: "OK"
        case 201: "Created"
        case 202: "Accepted"
        case 204: "No Content"
        case 301: "Moved Permanently"
        case 302: "Found"
        case 304: "Not Modified"
        case 400: "Bad Request"
        case 401: "Unauthorized"
        case 403: "Forbidden"
        case 404: "Not Found"
        case 409: "Conflict"
        case 413: "Content Too Large"
        case 422: "Unprocessable Content"
        case 429: "Too Many Requests"
        case 500: "Internal Server Error"
        case 501: "Not Implemented"
        case 502: "Bad Gateway"
        case 503: "Service Unavailable"
        case 504: "Gateway Timeout"
        default: "Status \(status)"
        }
    }

    private static func sanitized(_ value: String) -> String {
        value.replacingOccurrences(of: "\r", with: " ").replacingOccurrences(of: "\n", with: " ")
    }
}
