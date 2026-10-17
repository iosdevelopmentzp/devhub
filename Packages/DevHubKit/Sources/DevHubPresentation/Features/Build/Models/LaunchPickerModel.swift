import Foundation
import DevHubDomain
import DevHubUI

struct LaunchPickerModel: Equatable {
    struct SimulatorOption: Identifiable, Equatable {
        let id: Simulator.ID
        var title: String
    }

    var title: String
    var simulators: [SimulatorOption]
    var selectedID: Simulator.ID?
    var launch: LaunchIdentityModel?
    var cleanInstallNote: CleanInstallNoteModel?
    var runTitle: String
    var runTint: Tint
    var canRun: Bool

    static let preview = LaunchPickerModel(
        title: "Build & Run feature/ABC-2324-paid-call on",
        simulators: [
            SimulatorOption(id: "1", title: "iPhone 16 Pro · iOS 18.2 · booted"),
            SimulatorOption(id: "2", title: "iPad Pro 11 · iOS 18.2")
        ],
        selectedID: "1",
        launch: .preview,
        cleanInstallNote: .preview,
        runTitle: "Build & Run",
        runTint: .green,
        canRun: true
    )
}
