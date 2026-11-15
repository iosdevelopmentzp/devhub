import Foundation

package struct TrackerCache<Value: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    package struct Entry: Codable, Equatable, Sendable {
        package var value: Value
        package var readAt: Date

        package init(value: Value, readAt: Date) {
            self.value = value
            self.readAt = readAt
        }
    }

    package private(set) var entries: [String: Entry] = [:]

    package init(entries: [String: Entry] = [:]) {
        self.entries = entries
    }

    package var values: [String: Value] {
        entries.mapValues(\.value)
    }

    package func entry(for key: String) -> Entry? {
        entries[key]
    }

    package mutating func save(_ value: Value, for key: String, at date: Date, limit: Int) {
        entries[key] = Entry(value: value, readAt: date)
        guard entries.count > limit else { return }
        let kept = entries
            .sorted { $0.value.readAt > $1.value.readAt }
            .prefix(max(limit, 0))
        entries = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
    }
}
