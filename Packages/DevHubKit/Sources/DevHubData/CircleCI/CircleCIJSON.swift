import Foundation
import DevHubDomain

enum CircleCIJSON {
    static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw CIError.command("Cannot read the answer of circleci: \(error.localizedDescription)")
        }
    }

    static func decodeLines<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> [Value] {
        if let list = try? decode([Value].self, from: data) {
            return list
        }
        let text = String(decoding: data, as: UTF8.self)
        return try text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.isEmpty == false }
            .map { try decode(type, from: Data($0.utf8)) }
    }
}
