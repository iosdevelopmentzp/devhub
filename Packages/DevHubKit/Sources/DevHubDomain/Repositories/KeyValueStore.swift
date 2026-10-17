import Foundation

package protocol KeyValueStore: AnyObject, Sendable {
    func string(forKey key: String) -> String?
    func strings(forKey key: String) -> [String]?
    func bool(forKey key: String) -> Bool
    func integer(forKey key: String) -> Int
    func doubles(forKey key: String) -> [Double]?
    func stringMap(forKey key: String) -> [String: String]?
    func data(forKey key: String) -> Data?
    func set(_ value: String?, forKey key: String)
    func set(_ value: [String], forKey key: String)
    func set(_ value: Bool, forKey key: String)
    func set(_ value: Int, forKey key: String)
    func set(_ value: [Double], forKey key: String)
    func set(_ value: [String: String], forKey key: String)
    func set(_ value: Data?, forKey key: String)
    func remove(forKey key: String)
}

package extension KeyValueStore {
    func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func encode<T: Encodable>(_ value: T?, forKey key: String) {
        guard let value, let data = try? JSONEncoder().encode(value) else {
            remove(forKey: key)
            return
        }
        set(data, forKey: key)
    }
}
