import Foundation
import DevHubDomain
import DevHubUI

struct RunBarModel: Equatable {
    struct Target: Equatable {
        var id: Simulator.ID
        var name: String
        var icon: String
        var runtimeTag: TagModel?
        var identity: IdentitySummaryModel?
        var identityMissingText: String?
        var launch: LaunchIdentityModel?
        var cleanInstallNote: CleanInstallNoteModel?
    }

    struct Progress: Equatable {
        var step: String
        var value: Double?
    }

    struct Outcome: Equatable {
        var tint: Tint
        var text: String
    }

    var targetLabel: String
    var target: Target?
    var noTargetText: String
    var progress: Progress?
    var outcome: Outcome?
    var isRunning: Bool
    var canRun: Bool
    var canShowLog: Bool
    var canRefreshSimulators: Bool

    static let preview = RunBarModel(
        targetLabel: "Target",
        target: Target(
            id: "8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13",
            name: "iPhone 16 Pro",
            icon: "iphone",
            runtimeTag: TagModel("iOS 18.2"),
            identity: .preview,
            identityMissingText: nil,
            launch: .preview,
            cleanInstallNote: .preview
        ),
        noTargetText: "No simulator selected",
        progress: nil,
        outcome: Outcome(tint: .green, text: "Launched on iPhone 16 Pro · 2 min ago"),
        isRunning: false,
        canRun: true,
        canShowLog: true,
        canRefreshSimulators: true
    )
}
