import Foundation
import DevHubDomain
import DevHubUI

enum CrashBannerMapper {
    static let frameLimit = 15

    static func model(for report: CrashReport, isOpen: Bool) -> CrashBannerModel {
        let frames = report.frames.prefix(frameLimit).enumerated().map { index, frame in
            CrashBannerModel.FrameRow(
                id: index,
                text: "\(frame.image) · \(frame.symbol ?? "?")",
                place: CrashReportPolicy.place(of: frame),
                isApp: frame.isApp
            )
        }
        return CrashBannerModel(
            id: report.id,
            title: "\(report.processName) crashed",
            detail: detail(for: report),
            timeText: report.date.relativeDescription,
            messages: report.messages,
            frames: isOpen ? frames : [],
            hiddenFrameCount: isOpen ? max(report.frames.count - frameLimit, 0) : 0,
            isOpen: isOpen,
            reportPath: report.path,
            toggleTitle: isOpen ? "Hide Stack" : "Show Stack"
        )
    }

    static func detail(for report: CrashReport) -> String {
        let frame = CrashReportPolicy.topAppFrame(of: report).map { frame in
            [frame.symbol, CrashReportPolicy.place(of: frame).map { "at \($0)" }].compactMap { $0 }.joined(separator: " ")
        }
        let parts = [CrashReportPolicy.exception(of: report), frame].compactMap { $0 }
        return parts.isEmpty ? "No exception in the report" : parts.joined(separator: " · ")
    }
}
