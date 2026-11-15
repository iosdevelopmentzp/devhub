import Foundation
import Testing
@testable import DevHubDomain

@Suite struct TrackerCacheTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func aSavedValueComesBackWithItsReadTime() {
        var cache = TrackerCache<[String]>()

        cache.save(["ABC-123"], for: "mine", at: start, limit: 3)

        #expect(cache.entry(for: "mine") == TrackerCache.Entry(value: ["ABC-123"], readAt: start))
        #expect(cache.entry(for: "sprint") == nil)
        #expect(cache.values == ["mine": ["ABC-123"]])
    }

    @Test func aSecondSaveReplacesTheValueOfTheKey() {
        var cache = TrackerCache<[String]>()

        cache.save(["ABC-123"], for: "mine", at: start, limit: 3)
        cache.save(["ABC-124"], for: "mine", at: start.addingTimeInterval(60), limit: 3)

        #expect(cache.entries.count == 1)
        #expect(cache.entry(for: "mine")?.value == ["ABC-124"])
        #expect(cache.entry(for: "mine")?.readAt == start.addingTimeInterval(60))
    }

    @Test func theOldestEntriesLeaveWhenTheLimitIsPassed() {
        var cache = TrackerCache<String>()

        cache.save("first", for: "a", at: start, limit: 2)
        cache.save("second", for: "b", at: start.addingTimeInterval(10), limit: 2)
        cache.save("third", for: "c", at: start.addingTimeInterval(20), limit: 2)

        #expect(cache.values == ["b": "second", "c": "third"])
    }

    @Test func aKeyThatIsReadAgainStaysInTheCache() {
        var cache = TrackerCache<String>()

        cache.save("first", for: "a", at: start, limit: 2)
        cache.save("second", for: "b", at: start.addingTimeInterval(10), limit: 2)
        cache.save("first again", for: "a", at: start.addingTimeInterval(20), limit: 2)
        cache.save("third", for: "c", at: start.addingTimeInterval(30), limit: 2)

        #expect(cache.values == ["a": "first again", "c": "third"])
    }

    @Test func theCacheSurvivesEncodingAndDecoding() throws {
        var cache = TrackerCache<[String]>()
        cache.save(["ABC-123", "ABC-124"], for: "mine", at: start, limit: 3)

        let data = try JSONEncoder().encode(cache)
        let decoded = try JSONDecoder().decode(TrackerCache<[String]>.self, from: data)

        #expect(decoded == cache)
    }
}
