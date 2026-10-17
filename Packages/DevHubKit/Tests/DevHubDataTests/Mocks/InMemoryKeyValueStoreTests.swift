import Testing
@testable import DevHubMocks

@Suite struct InMemoryKeyValueStoreTests {
    private let store = InMemoryKeyValueStore()

    @Test func string() { KeyValueStoreRoundTrip.string(store) }
    @Test func strings() { KeyValueStoreRoundTrip.strings(store) }
    @Test func bool() { KeyValueStoreRoundTrip.bool(store) }
    @Test func integer() { KeyValueStoreRoundTrip.integer(store) }
    @Test func doubles() { KeyValueStoreRoundTrip.doubles(store) }
    @Test func stringMap() { KeyValueStoreRoundTrip.stringMap(store) }
    @Test func data() { KeyValueStoreRoundTrip.data(store) }
    @Test func remove() { KeyValueStoreRoundTrip.remove(store) }
    @Test func codable() { KeyValueStoreRoundTrip.codable(store) }
}
