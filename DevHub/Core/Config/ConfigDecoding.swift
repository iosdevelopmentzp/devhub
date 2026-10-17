import Foundation

nonisolated enum ConfigDecoding {
    static func decode<T: Decodable>(_ type: T.Type, from object: Any) throws -> T {
        guard JSONSerialization.isValidJSONObject(object) else {
            throw ConfigFailure(message: "The content is not a JSON object or array.")
        }
        let data = try JSONSerialization.data(withJSONObject: object)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw ConfigFailure(message: describe(error))
        }
    }

    static func parseJSON(_ text: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw ConfigFailure(message: "The file is not UTF-8 text.")
        }
        do {
            return try JSONSerialization.jsonObject(with: data)
        } catch {
            throw ConfigFailure(message: "Invalid JSON: \(jsonReason(error))")
        }
    }

    static func describe(_ error: Error) -> String {
        guard let decoding = error as? DecodingError else { return error.localizedDescription }
        switch decoding {
        case let .keyNotFound(key, context):
            return "\(path(context.codingPath + [key])): this key is required."
        case let .typeMismatch(_, context), let .valueNotFound(_, context):
            return "\(path(context.codingPath)): \(context.debugDescription)"
        case let .dataCorrupted(context):
            let location = context.codingPath.isEmpty ? "" : path(context.codingPath) + ": "
            return location + context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }

    static func deepMerge(_ base: [String: Any], _ top: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in top {
            if let baseObject = result[key] as? [String: Any], let topObject = value as? [String: Any] {
                result[key] = deepMerge(baseObject, topObject)
            } else {
                result[key] = value
            }
        }
        return result
    }

    private static func path(_ keys: [CodingKey]) -> String {
        let text = keys.map { $0.intValue.map { "[\($0)]" } ?? "." + $0.stringValue }.joined()
        return text.hasPrefix(".") ? String(text.dropFirst()) : text
    }

    private static func jsonReason(_ error: Error) -> String {
        let info = (error as NSError).userInfo
        let reason = (info[NSDebugDescriptionErrorKey] as? String) ?? error.localizedDescription
        return reason.hasSuffix(".") ? String(reason.dropLast()) : reason
    }
}

nonisolated struct ConfigFailure: Error, LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
