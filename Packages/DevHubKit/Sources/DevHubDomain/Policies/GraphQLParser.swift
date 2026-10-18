import Foundation

package enum GraphQLParser {

    package static func exchange(method: String, query: String?, requestBody: String, responseBody: String) -> GraphQLExchange? {
        let operations = method.uppercased() == "GET" ? operations(query: query) : operations(body: requestBody)
        guard operations.isEmpty == false else { return nil }
        return GraphQLExchange(operations: operations, errors: errors(responseBody: responseBody))
    }

    package static func operations(body: String) -> [GraphQLOperation] {
        guard let object = json(body) else { return [] }
        if let batch = object as? [[String: Any]] {
            return batch.compactMap(operation(from:))
        }
        return (object as? [String: Any]).flatMap(operation(from:)).map { [$0] } ?? []
    }

    package static func operations(query: String?) -> [GraphQLOperation] {
        guard let query, let items = URLComponents(string: "?" + query.trimmingPrefix("?"))?.queryItems else { return [] }
        let values = Dictionary(items.compactMap { item in item.value.map { (item.name, $0) } }) { first, _ in first }
        guard let text = values["query"], let parsed = parse(text) else { return [] }
        return [GraphQLOperation(name: values["operationName"].flatMap(nonEmpty) ?? parsed.name, kind: parsed.kind, variables: values["variables"].flatMap(nonEmpty))]
    }

    package static func errors(responseBody: String) -> [String] {
        let objects: [[String: Any]]
        switch json(responseBody) {
        case let object as [String: Any]: objects = [object]
        case let batch as [[String: Any]]: objects = batch
        default: return []
        }
        return objects.flatMap { object in
            (object["errors"] as? [[String: Any]] ?? []).map { $0["message"] as? String ?? "Unknown GraphQL error" }
        }
    }

    package static func parse(_ document: String) -> (name: String?, kind: GraphQLOperation.Kind)? {
        let text = document.trimmed
        guard text.isEmpty == false else { return nil }
        if text.hasPrefix("{") {
            return (nil, .query)
        }
        let pattern = #"^\s*(query|mutation|subscription)\b\s*([_A-Za-z][_0-9A-Za-z]*)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let kindRange = Range(match.range(at: 1), in: text),
              let kind = GraphQLOperation.Kind(rawValue: String(text[kindRange])) else { return nil }
        let name = Range(match.range(at: 2), in: text).map { String(text[$0]) }
        return (name, kind)
    }

    private static func operation(from object: [String: Any]) -> GraphQLOperation? {
        guard let document = object["query"] as? String, let parsed = parse(document) else {
            guard let name = (object["operationName"] as? String).flatMap(nonEmpty), object["extensions"] != nil else { return nil }
            return GraphQLOperation(name: name, kind: .query, variables: variables(object["variables"]))
        }
        let name = (object["operationName"] as? String).flatMap(nonEmpty) ?? parsed.name
        return GraphQLOperation(name: name, kind: parsed.kind, variables: variables(object["variables"]))
    }

    private static func variables(_ value: Any?) -> String? {
        guard let value, value is NSNull == false else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]) else { return nil }
        let text = String(decoding: data, as: UTF8.self)
        return text == "{\n\n}" || text == "{}" ? nil : text
    }

    private static func json(_ text: String) -> Any? {
        let trimmed = text.trimmed
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else { return nil }
        return try? JSONSerialization.jsonObject(with: Data(trimmed.utf8))
    }

    private static func nonEmpty(_ text: String) -> String? {
        let trimmed = text.trimmed
        return trimmed.isEmpty ? nil : trimmed
    }
}
