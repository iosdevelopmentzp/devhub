import Foundation
import DevHubDomain

enum NetworkSourceLineParser {
    enum Line: Equatable {
        case request(NetworkRequest)
        case error(String)
        case other
    }

    static let maxBody = 512 * 1024

    static func parse(_ line: String, id: (String?) -> Int) -> Line {
        guard line.hasPrefix(ScriptDirectiveParser.marker) else { return .other }
        let json = Data(line.dropFirst(ScriptDirectiveParser.marker.count).utf8)
        guard let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else {
            return .error("A network source line is not one JSON object.")
        }
        if let raw = object["request"] {
            return request(from: raw, id: id)
        }
        if let message = object["error"] as? String {
            return .error(message)
        }
        return .other
    }

    private static func request(from raw: Any, id: (String?) -> Int) -> Line {
        guard JSONSerialization.isValidJSONObject(raw), let data = try? JSONSerialization.data(withJSONObject: raw) else {
            return .error("The request directive is not a JSON object.")
        }
        do {
            let entry = try JSONDecoder().decode(Entry.self, from: data)
            return .request(entry.request(id: id(entry.id)))
        } catch let DecodingError.keyNotFound(key, _) {
            return .error("The request directive has no \(key.stringValue).")
        } catch let DecodingError.typeMismatch(_, context), let DecodingError.dataCorrupted(context) {
            let field = context.codingPath.map(\.stringValue).joined(separator: ".")
            return .error("The request directive has a wrong \(field.isEmpty ? "value" : field): \(context.debugDescription)")
        } catch {
            return .error("The request directive is not valid: \(error.localizedDescription)")
        }
    }

    private struct Entry: Decodable {
        var id: String?
        var method: String
        var url: String
        var status: Int?
        var statusText: String?
        var startedAt: Date?
        var durationMs: Double?
        var requestHeaders: [String: String]?
        var requestBody: String?
        var responseHeaders: [String: String]?
        var responseBody: String?
        var error: String?

        private enum CodingKeys: String, CodingKey {
            case id, method, url, status, statusText, startedAt, durationMs, requestHeaders, requestBody, responseHeaders, responseBody, error
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let number = try? container.decodeIfPresent(Int.self, forKey: .id) {
                id = String(number)
            } else {
                id = try container.decodeIfPresent(String.self, forKey: .id)
            }
            method = try container.decode(String.self, forKey: .method)
            url = try container.decode(String.self, forKey: .url)
            status = try container.decodeIfPresent(Int.self, forKey: .status)
            statusText = try container.decodeIfPresent(String.self, forKey: .statusText)
            if let seconds = try? container.decodeIfPresent(Double.self, forKey: .startedAt) {
                startedAt = Date(timeIntervalSince1970: seconds)
            } else if let text = try container.decodeIfPresent(String.self, forKey: .startedAt) {
                guard let date = ISO8601.date(from: text) else {
                    throw DecodingError.dataCorruptedError(forKey: .startedAt, in: container, debugDescription: "use ISO 8601 with a time zone, or Unix seconds")
                }
                startedAt = date
            }
            durationMs = try container.decodeIfPresent(Double.self, forKey: .durationMs)
            requestHeaders = try container.decodeIfPresent([String: String].self, forKey: .requestHeaders)
            requestBody = try container.decodeIfPresent(String.self, forKey: .requestBody)
            responseHeaders = try container.decodeIfPresent([String: String].self, forKey: .responseHeaders)
            responseBody = try container.decodeIfPresent(String.self, forKey: .responseBody)
            error = try container.decodeIfPresent(String.self, forKey: .error)
        }

        func request(id: Int) -> NetworkRequest {
            let parsed = URL(string: url)
            let isRelative = parsed?.host == nil
            let requestText = NetworkSourceLineParser.capped(requestBody ?? "")
            let responseText = NetworkSourceLineParser.capped(responseBody ?? "")
            let graphQL = GraphQLParser.exchange(method: method, query: parsed?.query, requestBody: requestText, responseBody: responseText)
            let request = NetworkRequest(
                id: id,
                method: method.uppercased(),
                url: url,
                path: isRelative ? String(url.prefix { $0 != "?" }) : (parsed?.path).flatMap { $0.isEmpty ? "/" : $0 } ?? url,
                host: parsed?.host ?? "",
                statusCode: status,
                statusText: statusText ?? "",
                startedAt: startedAt,
                duration: durationMs.map { $0 / 1000 },
                requestBody: requestText,
                responseBody: responseText,
                responseHeaders: NetworkSourceLineParser.headers(responseHeaders),
                error: error,
                isFailure: error != nil || (status ?? 0) >= 400 || graphQL?.errors.isEmpty == false,
                requestHeaders: NetworkSourceLineParser.headers(requestHeaders),
                graphQL: graphQL,
                origin: .sourceScript
            )
            return NetworkRequestRedactor.redact(request)
        }
    }

    private static func headers(_ values: [String: String]?) -> [HTTPHeader] {
        (values ?? [:])
            .map { HTTPHeader(name: $0.key, value: $0.value) }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private static func capped(_ text: String) -> String {
        guard text.utf8.count > maxBody else { return text }
        return String(decoding: text.utf8.prefix(maxBody), as: UTF8.self) + "\n… cut at \(maxBody / 1024) KB"
    }
}
