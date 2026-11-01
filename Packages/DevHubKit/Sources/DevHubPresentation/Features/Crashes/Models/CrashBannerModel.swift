import Foundation
import DevHubDomain
import DevHubUI

struct CrashBannerModel: Identifiable, Equatable {
    struct FrameRow: Identifiable, Equatable {
        let id: Int
        var text: String
        var place: String?
        var isApp: Bool
    }

    let id: CrashReport.ID
    var title: String
    var detail: String
    var timeText: String
    var messages: [String]
    var frames: [FrameRow]
    var hiddenFrameCount: Int
    var isOpen: Bool
    var reportPath: String
    var toggleTitle: String

    static let preview = CrashBannerModel(
        id: "~/Library/Logs/DiagnosticReports/ExampleApp-2026-11-01-140509.ips",
        title: "ExampleApp crashed",
        detail: "EXC_BREAKPOINT (SIGTRAP) · ProfileViewModel.load() at ProfileViewModel.swift:42",
        timeText: "2 min. ago",
        messages: ["ExampleApp/ProfileViewModel.swift:42: Fatal error: Unexpectedly found nil while unwrapping an Optional value"],
        frames: [
            FrameRow(id: 0, text: "libswiftCore.dylib · _assertionFailure(_:_:file:line:flags:)", place: nil, isApp: false),
            FrameRow(id: 1, text: "ExampleApp.debug.dylib · ProfileViewModel.load()", place: "ProfileViewModel.swift:42", isApp: true),
        ],
        hiddenFrameCount: 0,
        isOpen: true,
        reportPath: "~/Library/Logs/DiagnosticReports/ExampleApp-2026-11-01-140509.ips",
        toggleTitle: "Hide Stack"
    )
}
