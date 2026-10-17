import Foundation
import DevHubDomain
import DevHubUI

struct MockServerBarModel: Equatable {
    struct ModeOption: Identifiable, Equatable {
        let id: MockMode
        var title: String
    }

    struct SetOption: Identifiable, Equatable {
        let id: MockSet.ID
        var title: String
    }

    var modes: [ModeOption]
    var mode: MockMode
    var showsSetPicker: Bool
    var sets: [SetOption]
    var selectedSetID: MockSet.ID?
    var applyTitle: String
    var canApply: Bool
    var isApplyProminent: Bool
    var statusText: String
    var statusTint: Tint
    var statusHint: String
    var appText: String?
    var appTint: Tint
    var appHint: String
    var error: String?

    static let limitsHint = "Debug builds only. REST and Socket.IO move to DevHub; CDN images, uploads and SDK traffic do not. Prod cannot be mocked. Switching needs a relaunch. While the server runs, session-log rows for this simulator are hidden, so every request shows once."

    static let preview = MockServerBarModel(
        modes: MockServerBarMapper.modeOptions,
        mode: .mock,
        showsSetPicker: true,
        sets: [SetOption(id: UUID(), title: "VIP user")],
        selectedSetID: nil,
        applyTitle: "Apply & Relaunch",
        canApply: true,
        isApplyProminent: true,
        statusText: "Port 52001 → api-qa.example.com",
        statusTint: .green,
        statusHint: "The app on this simulator talks to http://127.0.0.1:52001",
        appText: "App goes through DevHub (127.0.0.1:52001)",
        appTint: .green,
        appHint: "The app's last requests went to the DevHub server",
        error: nil
    )
}
