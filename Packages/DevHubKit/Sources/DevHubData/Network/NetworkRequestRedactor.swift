import Foundation
import DevHubDomain

enum NetworkRequestRedactor {
    private static let droppedHeaders: Set<String> = ["authorization", "cookie", "set-cookie", "proxy-authorization"]
    private static let mask = "•••"

    static func redact(_ request: NetworkRequest) -> NetworkRequest {
        var redacted = request
        redacted.url = LogRedactor.redact(request.url)
        redacted.path = LogRedactor.redact(request.path)
        redacted.requestBody = LogRedactor.redact(request.requestBody)
        redacted.responseBody = LogRedactor.redact(request.responseBody)
        redacted.responseHeaders = headers(request.responseHeaders)
        redacted.requestHeaders = headers(request.requestHeaders)
        redacted.error = request.error.map(LogRedactor.redact)
        return redacted
    }

    static func headers(_ headers: [HTTPHeader]) -> [HTTPHeader] {
        headers
            .filter { droppedHeaders.contains($0.name.lowercased()) == false }
            .map { HTTPHeader(name: $0.name, value: value(of: $0)) }
    }

    private static func value(of header: HTTPHeader) -> String {
        let prefix = "\(header.name): "
        let line = LogRedactor.redact(prefix + header.value)
        guard line.hasPrefix(prefix) else { return mask }
        return String(line.dropFirst(prefix.count))
    }
}
