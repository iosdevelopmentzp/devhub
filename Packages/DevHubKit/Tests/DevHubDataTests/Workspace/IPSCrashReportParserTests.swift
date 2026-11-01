import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct IPSCrashReportParserTests {
    private let fallback = Date(timeIntervalSince1970: 1_000)

    @Test func readsTheHeaderTheExceptionAndTheMessages() throws {
        let report = try #require(IPSCrashReportParser.parse(CrashReportFixture.simulatorCrash, path: "/reports/ExampleApp.ips", fallbackDate: fallback))

        #expect(report.path == "/reports/ExampleApp.ips")
        #expect(report.processName == "ExampleApp")
        #expect(report.bundleID == "com.example.app")
        #expect(report.appVersion == "1.5.2")
        #expect(report.date == IPSCrashReportParser.date("2026-11-01 14:05:09 +0200"))
        #expect(report.date != fallback)
        #expect(report.simulatorID == CrashReportFixture.simulatorID)
        #expect(report.exceptionType == "EXC_BREAKPOINT")
        #expect(report.signal == "SIGTRAP")
        #expect(report.subtype == "Trace/BPT trap: 5")
        #expect(report.messages == ["ExampleApp/ProfileViewModel.swift:42: Fatal error: Unexpectedly found nil while unwrapping an Optional value"])
    }

    @Test func framesComeFromTheFaultingThreadAndMarkTheApp() throws {
        let report = try #require(IPSCrashReportParser.parse(CrashReportFixture.simulatorCrash, path: "/r.ips", fallbackDate: fallback))

        #expect(report.frames == [
            CrashReport.Frame(image: "libswiftCore.dylib", symbol: "_assertionFailure(_:_:file:line:flags:)", file: nil, line: nil, isApp: false),
            CrashReport.Frame(image: "ExampleApp.debug.dylib", symbol: "ProfileViewModel.load()", file: "ProfileViewModel.swift", line: 42, isApp: true),
            CrashReport.Frame(image: "ExampleApp.debug.dylib", symbol: "closure #1 in ProfileView.body.getter", file: "ProfileView.swift", line: 18, isApp: true),
            CrashReport.Frame(image: "SwiftUI", symbol: nil, file: nil, line: nil, isApp: false),
        ])
    }

    @Test func aMacAppHasNoSimulator() throws {
        let report = try #require(IPSCrashReportParser.parse(CrashReportFixture.macCrash, path: "/r.ips", fallbackDate: fallback))

        #expect(report.simulatorID == nil)
        #expect(report.frames.isEmpty)
        #expect(report.messages.isEmpty)
    }

    @Test func brokenTextGivesNoReport() {
        #expect(IPSCrashReportParser.parse("", path: "/r.ips", fallbackDate: fallback) == nil)
        #expect(IPSCrashReportParser.parse("not json\n{}", path: "/r.ips", fallbackDate: fallback) == nil)
        #expect(IPSCrashReportParser.parse(#"{"bug_type":"309"}"#, path: "/r.ips", fallbackDate: fallback) == nil)
    }

    @Test func aReportWithoutATimestampUsesTheFileDate() throws {
        let report = try #require(IPSCrashReportParser.parse(#"{"name":"ExampleApp","bug_type":"309"}"#, path: "/r.ips", fallbackDate: fallback))

        #expect(report.date == fallback)
    }

    @Test func theSimulatorIDNeedsTheFullUUID() {
        #expect(IPSCrashReportParser.simulatorID(in: "/x/CoreSimulator/Devices/\(CrashReportFixture.simulatorID)/data/a.app/a") == CrashReportFixture.simulatorID)
        #expect(IPSCrashReportParser.simulatorID(in: "/x/CoreSimulator/Devices/short/data") == nil)
        #expect(IPSCrashReportParser.simulatorID(in: "/Applications/Notes.app/Contents/MacOS/Notes") == nil)
    }

    @Test func theTimestampKeepsItsZone() {
        let date = IPSCrashReportParser.date("2026-11-01 14:05:09.1234 +0200")

        #expect(date == Date(timeIntervalSince1970: 1_793_534_709))
    }
}
