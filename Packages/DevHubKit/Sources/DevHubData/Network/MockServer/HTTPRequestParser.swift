import Foundation
import DevHubDomain

enum HTTPRequestParser {
    enum Outcome: Equatable {
        case incomplete
        case complete(MockHTTPRequest)
        case invalid(String)
        case unsupported(String)
    }

    static let maxHeaderSize = 64 * 1024
    static let maxBodySize = 32 * 1024 * 1024

    private static let headerEnd = Data("\r\n\r\n".utf8)
    private static let emptyChunkedBody = Data("0\r\n\r\n".utf8)

    static func parse(_ data: Data) -> Outcome {
        guard let end = data.range(of: headerEnd) else {
            return data.count > maxHeaderSize ? .invalid("Request headers are too large.") : .incomplete
        }
        guard let head = String(data: data[data.startIndex..<end.lowerBound], encoding: .utf8) else {
            return .invalid("Request headers are not UTF-8.")
        }
        let lines = head.components(separatedBy: "\r\n")
        let parts = lines[0].split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 3, parts[2].hasPrefix("HTTP/1.") else {
            return .invalid("Malformed request line.")
        }
        let headers = lines.dropFirst().compactMap(header(from:))
        let rest = data[end.upperBound...]
        let request = MockHTTPRequest(method: parts[0].uppercased(), target: String(parts[1]), version: String(parts[2]), headers: headers, body: Data())
        if let encoding = request.header("Transfer-Encoding"), encoding.lowercased().contains("chunked") {
            return chunked(request, rest: rest)
        }
        let length = request.header("Content-Length").map { Int($0.trimmingCharacters(in: .whitespaces)) } ?? 0
        guard let length, length >= 0 else { return .invalid("Malformed Content-Length.") }
        guard length <= maxBodySize else { return .unsupported("Request body is larger than \(maxBodySize) bytes.") }
        guard rest.count >= length else { return .incomplete }
        var complete = request
        complete.body = Data(rest.prefix(length))
        return .complete(complete)
    }

    private static func header(from line: String) -> HTTPHeader? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let name = line[..<colon].trimmingCharacters(in: .whitespaces)
        guard name.isEmpty == false else { return nil }
        return HTTPHeader(name: name, value: line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces))
    }

    private static func chunked(_ request: MockHTTPRequest, rest: Data) -> Outcome {
        if rest.starts(with: emptyChunkedBody) {
            return .complete(request)
        }
        if rest.count < emptyChunkedBody.count, emptyChunkedBody.starts(with: rest) {
            return .incomplete
        }
        return .unsupported("Chunked request bodies are not supported by the DevHub mock server.")
    }
}
