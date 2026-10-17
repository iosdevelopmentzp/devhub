import Foundation
import Testing
@testable import DevHubData

@Suite struct ISO8601Tests {
    private static let reference: TimeInterval = 1_767_323_045

    @Test func parsesPlainDate() throws {
        let date = try #require(ISO8601.date(from: "2026-01-02T03:04:05Z"))
        #expect(date.timeIntervalSince1970 == Self.reference)
    }

    @Test func parsesFractionalSeconds() throws {
        let date = try #require(ISO8601.date(from: "2026-01-02T03:04:05.250Z"))
        #expect(abs(date.timeIntervalSince1970 - (Self.reference + 0.25)) < 0.001)
    }

    @Test func parsesTimeZoneOffset() throws {
        let date = try #require(ISO8601.date(from: "2026-01-02T05:04:05+02:00"))
        #expect(date.timeIntervalSince1970 == Self.reference)
    }

    @Test(arguments: ["", "yesterday", "2026-01-02", "2026-13-45T99:00:00Z"])
    func returnsNilForInvalidText(text: String) {
        #expect(ISO8601.date(from: text) == nil)
    }
}
