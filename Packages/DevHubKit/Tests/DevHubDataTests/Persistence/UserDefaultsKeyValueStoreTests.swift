import Foundation
import Testing
@testable import DevHubData

@Suite final class UserDefaultsKeyValueStoreTests {
    private let suiteName = "DevHubTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let store: UserDefaultsKeyValueStore

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        store = UserDefaultsKeyValueStore(defaults: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func string() { KeyValueStoreRoundTrip.string(store) }
    @Test func strings() { KeyValueStoreRoundTrip.strings(store) }
    @Test func bool() { KeyValueStoreRoundTrip.bool(store) }
    @Test func integer() { KeyValueStoreRoundTrip.integer(store) }
    @Test func doubles() { KeyValueStoreRoundTrip.doubles(store) }
    @Test func stringMap() { KeyValueStoreRoundTrip.stringMap(store) }
    @Test func data() { KeyValueStoreRoundTrip.data(store) }
    @Test func remove() { KeyValueStoreRoundTrip.remove(store) }
    @Test func codable() { KeyValueStoreRoundTrip.codable(store) }

    @Test func writesThroughToTheDefaultsSuite() {
        store.set("value" as String?, forKey: "key")

        #expect(defaults.string(forKey: "key") == "value")
    }
}
