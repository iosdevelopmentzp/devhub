import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct AppLogParserTests {
    @Test func parsesNdjsonLine() throws {
        let line = #"{"timestamp":"2026-01-02 03:04:05.123456+0000","messageType":"Error","subsystem":"com.app","category":"network","eventMessage":"GET /v1/profile 500"}"#

        let parsed = try #require(AppLogParser.parse(line, id: 7))

        #expect(parsed.id == 7)
        #expect(parsed.level == .error)
        #expect(parsed.category == "com.app · network")
        #expect(parsed.message == "GET /v1/profile 500")
        let date = try #require(parsed.date)
        #expect(abs(date.timeIntervalSince1970 - 1_767_323_045.123) < 0.001)
    }

    @Test(arguments: [
        ("Debug", AppLogLine.Level.debug),
        ("Info", .info),
        ("Error", .error),
        ("Fault", .fault),
        ("Default", .notice),
        ("Activity", .notice),
    ])
    func mapsLevel(type: String, expected: AppLogLine.Level) {
        let line = #"{"messageType":"\#(type)","eventMessage":"m"}"#
        #expect(AppLogParser.parse(line, id: 1)?.level == expected)
    }

    @Test func missingTypeIsNotice() {
        #expect(AppLogParser.parse(#"{"eventMessage":"m"}"#, id: 1)?.level == .notice)
    }

    @Test(arguments: [
        (#"{"subsystem":"","category":"ui","eventMessage":"m"}"#, "ui"),
        (#"{"subsystem":"com.app","category":"","eventMessage":"m"}"#, "com.app"),
        (#"{"subsystem":"com.app","eventMessage":"m"}"#, "com.app"),
        (#"{"eventMessage":"m"}"#, ""),
    ])
    func dropsEmptyCategoryParts(line: String, expected: String) {
        #expect(AppLogParser.parse(line, id: 1)?.category == expected)
    }

    @Test func redactsTheMessage() {
        let line = #"{"eventMessage":"request token=abc123 sent"}"#
        #expect(AppLogParser.parse(line, id: 1)?.message == "request token=••• sent")
    }

    @Test func unreadableTimestampIsNil() {
        let line = #"{"timestamp":"yesterday","eventMessage":"m"}"#
        #expect(AppLogParser.parse(line, id: 1)?.date == nil)
    }

    @Test(arguments: [
        "Filtering the log data using \"process == \\\"App\\\"\"",
        #"{"messageType":"Info","subsystem":"com.app"}"#,
        "{broken",
        "",
        #" {"eventMessage":"leading space"}"#,
    ])
    func returnsNilForOtherLines(line: String) {
        #expect(AppLogParser.parse(line, id: 1) == nil)
    }
}
