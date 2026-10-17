import Foundation

extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String? {
        guard contains(key), try decodeNil(forKey: key) == false else { return nil }
        if let text = try? decode(String.self, forKey: key) {
            return text
        }
        if let flag = try? decode(Bool.self, forKey: key) {
            return flag ? "true" : "false"
        }
        if let number = try? decode(Int.self, forKey: key) {
            return String(number)
        }
        if let number = try? decode(Double.self, forKey: key) {
            return String(number)
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Expected a string, a number or true or false.")
        )
    }
}
