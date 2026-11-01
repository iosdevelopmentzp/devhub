import Foundation
import DevHubDomain

extension MockData {
    package static let crashReport = CrashReport(
        path: "~/Library/Logs/DiagnosticReports/ExampleApp-2026-11-01-140509.ips",
        processName: "ExampleApp",
        bundleID: "com.example.app",
        appVersion: "1.5.2",
        date: Date(timeIntervalSince1970: 1_793_000_000),
        simulatorID: "8A1F0C2E-5B6D-4E7F-9A0B-1C2D3E4F5A6B",
        exceptionType: "EXC_BREAKPOINT",
        signal: "SIGTRAP",
        subtype: nil,
        messages: ["ExampleApp/ProfileViewModel.swift:42: Fatal error: Unexpectedly found nil while unwrapping an Optional value"],
        frames: [
            CrashReport.Frame(image: "libswiftCore.dylib", symbol: "_assertionFailure(_:_:file:line:flags:)", file: nil, line: nil, isApp: false),
            CrashReport.Frame(image: "ExampleApp.debug.dylib", symbol: "ProfileViewModel.load()", file: "ProfileViewModel.swift", line: 42, isApp: true),
            CrashReport.Frame(image: "ExampleApp.debug.dylib", symbol: "closure #1 in ProfileView.body.getter", file: "ProfileView.swift", line: 18, isApp: true),
            CrashReport.Frame(image: "SwiftUI", symbol: "ViewGraph.updateOutputs()", file: nil, line: nil, isApp: false),
        ]
    )
}
