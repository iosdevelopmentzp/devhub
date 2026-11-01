import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct DefaultsExportParserTests {
    @Test func readsEveryKindInKeyOrder() throws {
        let entries = try #require(DefaultsExportParser.entries(from: DefaultsExportFixture.appSuite))

        #expect(entries.map(\.key) == ["apiEnvironment", "featureFlags", "lastSyncDate", "launchCount", "onboardingDone", "recentSearches", "token", "volume"])
        #expect(entries.map(\.kind) == [.string, .dictionary, .date, .integer, .bool, .array, .data, .float])
    }

    @Test func writesTheValueAsText() throws {
        let entries = try #require(DefaultsExportParser.entries(from: DefaultsExportFixture.appSuite))
        let text = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.text) })

        #expect(text["apiEnvironment"] == "staging")
        #expect(text["launchCount"] == "14")
        #expect(text["volume"] == "0.5")
        #expect(text["onboardingDone"] == "true")
        #expect(text["lastSyncDate"] == "2026-10-30T09:41:00Z")
        #expect(text["token"] == "4 bytes")
        #expect(text["recentSearches"] == "[\"shoes\", 2]")
        #expect(text["featureFlags"] == "{checkout: true, search: false}")
    }

    @Test func anEmptyDomainHasNoEntries() {
        #expect(DefaultsExportParser.entries(from: DefaultsExportFixture.empty) == [])
    }

    @Test func textThatIsNotAPropertyListIsNil() {
        #expect(DefaultsExportParser.entries(from: "Domain not found") == nil)
    }

    @Test func longValuesAreCut() {
        let entry = DefaultsExportParser.entry(key: "log", value: String(repeating: "a", count: 400))

        #expect(entry.text.count == DefaultsExportParser.textLimit + 1)
        #expect(entry.text.hasSuffix("…"))
    }
}
