import Foundation

package enum CrashReportPolicy {
    package static let launchSlack: TimeInterval = 5

    package static func matches(_ report: CrashReport, bundleID: String, simulatorID: String?, launchedAt: Date) -> Bool {
        guard report.simulatorID != nil, report.bundleID == bundleID else { return false }
        guard report.date >= launchedAt.addingTimeInterval(-launchSlack) else { return false }
        guard let simulatorID, let reported = report.simulatorID else { return true }
        return reported.caseInsensitiveCompare(simulatorID) == .orderedSame
    }

    package static func topAppFrame(of report: CrashReport) -> CrashReport.Frame? {
        report.frames.first { $0.isApp && $0.symbol != nil }
    }

    package static func exception(of report: CrashReport) -> String? {
        switch (report.exceptionType, report.signal) {
        case let (type?, signal?): "\(type) (\(signal))"
        case let (type?, nil): type
        case let (nil, signal?): signal
        case (nil, nil): nil
        }
    }

    package static func place(of frame: CrashReport.Frame) -> String? {
        guard let file = frame.file else { return nil }
        guard let line = frame.line else { return file }
        return "\(file):\(line)"
    }
}
