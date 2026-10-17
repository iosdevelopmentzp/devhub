import Foundation
import DevHubDomain

package final class UserDefaultsKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    package init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    package func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    package func strings(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    package func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    package func integer(forKey key: String) -> Int {
        defaults.integer(forKey: key)
    }

    package func doubles(forKey key: String) -> [Double]? {
        defaults.array(forKey: key) as? [Double]
    }

    package func stringMap(forKey key: String) -> [String: String]? {
        defaults.dictionary(forKey: key) as? [String: String]
    }

    package func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    package func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: [String], forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: [Double], forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: [String: String], forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func set(_ value: Data?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    package func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
