import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CrashReportPolicyTests {
    private let launchedAt = Date(timeIntervalSince1970: 10_000)
    private let simulatorID = "8A1F0C2E-5B6D-4E7F-9A0B-1C2D3E4F5A6B"

    @Test func aCrashOfTheLaunchedAppMatches() {
        let crash = report(bundleID: "com.example.app", simulatorID: simulatorID, date: launchedAt.addingTimeInterval(30))

        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt))
        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: simulatorID.lowercased(), launchedAt: launchedAt))
        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: nil, launchedAt: launchedAt))
    }

    @Test func otherAppsSimulatorsAndOlderCrashesDoNotMatch() {
        let crash = report(bundleID: "com.example.app", simulatorID: simulatorID, date: launchedAt.addingTimeInterval(30))

        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.notes", simulatorID: simulatorID, launchedAt: launchedAt) == false)
        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: "OTHER", launchedAt: launchedAt) == false)
        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt.addingTimeInterval(60)) == false)
        #expect(CrashReportPolicy.matches(report(bundleID: "com.example.app", simulatorID: nil, date: launchedAt), bundleID: "com.example.app", simulatorID: nil, launchedAt: launchedAt) == false)
    }

    @Test func aCrashJustBeforeTheLaunchRecordStillMatches() {
        let crash = report(bundleID: "com.example.app", simulatorID: simulatorID, date: launchedAt.addingTimeInterval(-3))

        #expect(CrashReportPolicy.matches(crash, bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt))
    }

    @Test func theTopAppFrameSkipsSystemFramesAndFramesWithoutASymbol() {
        var crash = report(bundleID: "com.example.app", simulatorID: simulatorID, date: launchedAt)
        crash.frames = [
            CrashReport.Frame(image: "libswiftCore.dylib", symbol: "_assertionFailure", file: nil, line: nil, isApp: false),
            CrashReport.Frame(image: "ExampleApp", symbol: nil, file: nil, line: nil, isApp: true),
            CrashReport.Frame(image: "ExampleApp", symbol: "ProfileViewModel.load()", file: "ProfileViewModel.swift", line: 42, isApp: true),
        ]

        #expect(CrashReportPolicy.topAppFrame(of: crash)?.symbol == "ProfileViewModel.load()")
        crash.frames = []
        #expect(CrashReportPolicy.topAppFrame(of: crash) == nil)
    }

    @Test func theExceptionJoinsTypeAndSignal() {
        var crash = report(bundleID: nil, simulatorID: nil, date: launchedAt)
        #expect(CrashReportPolicy.exception(of: crash) == nil)

        crash.signal = "SIGSEGV"
        #expect(CrashReportPolicy.exception(of: crash) == "SIGSEGV")
        crash.exceptionType = "EXC_BAD_ACCESS"
        #expect(CrashReportPolicy.exception(of: crash) == "EXC_BAD_ACCESS (SIGSEGV)")
        crash.signal = nil
        #expect(CrashReportPolicy.exception(of: crash) == "EXC_BAD_ACCESS")
    }

    @Test func thePlaceNeedsAFile() {
        #expect(CrashReportPolicy.place(of: CrashReport.Frame(image: "A", symbol: "f", file: "A.swift", line: 7, isApp: true)) == "A.swift:7")
        #expect(CrashReportPolicy.place(of: CrashReport.Frame(image: "A", symbol: "f", file: "A.swift", line: nil, isApp: true)) == "A.swift")
        #expect(CrashReportPolicy.place(of: CrashReport.Frame(image: "A", symbol: "f", file: nil, line: 7, isApp: true)) == nil)
    }

    private func report(bundleID: String?, simulatorID: String?, date: Date) -> CrashReport {
        CrashReport(path: "/r.ips", processName: "ExampleApp", bundleID: bundleID, appVersion: nil, date: date, simulatorID: simulatorID, exceptionType: nil, signal: nil, subtype: nil, messages: [], frames: [])
    }
}
