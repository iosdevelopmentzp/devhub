import Foundation
import DevHubDomain
import DevHubUI

enum AppCrashText {
    static let frameLimit = 40

    static func lines(_ report: CrashReport) -> [String] {
        var lines = [
            "Process: \(report.processName) \(report.appVersion ?? "")".trimmingCharacters(in: .whitespaces),
            "Date: \(ISOTimestamp.text(report.date))",
            "Exception: \(CrashReportPolicy.exception(of: report) ?? "none")",
        ]
        lines += report.messages.map { "Message: \($0)" }
        lines.append("Frames:")
        for (index, frame) in report.frames.prefix(frameLimit).enumerated() {
            let place = CrashReportPolicy.place(of: frame).map { " (\($0))" } ?? ""
            lines.append("\(index) \(frame.image) \(frame.symbol ?? "?")\(place)")
        }
        if report.frames.count > frameLimit {
            lines.append("(\(report.frames.count - frameLimit) more frames)")
        }
        return lines
    }

    static func notice(_ report: CrashReport) -> String {
        let detail = CrashBannerMapper.detail(for: report)
        return "DevHub crashed \(report.date.relativeDescription): \(detail)"
    }
}
