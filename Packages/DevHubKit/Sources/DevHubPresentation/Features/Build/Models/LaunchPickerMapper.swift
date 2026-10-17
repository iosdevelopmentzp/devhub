import Foundation
import DevHubDomain
import DevHubUI

enum LaunchPickerMapper {

    static func model(
        subject: String,
        simulators: [Simulator],
        runtime: (Simulator.ID) -> String?,
        targetID: Simulator.ID?,
        config: DeviceIdentityConfig?,
        settings: SimulatorIdentitySettings,
        identity: AppIdentity?,
        savedDeviceIDs: [String],
        aliases: [String: String],
        cleanInstallIsOn: Bool,
        buildIsRunning: Bool
    ) -> LaunchPickerModel {
        let ordered = simulators.enumerated().sorted { lhs, rhs in
            (rank(lhs.element), lhs.offset) < (rank(rhs.element), rhs.offset)
        }
        let needsCleanInstall = config != nil && IdentityPanelMapper.needsCleanInstall(identity: identity, settings: settings, savedDeviceIDs: savedDeviceIDs)
        let willCleanInstall = cleanInstallIsOn || needsCleanInstall
        return LaunchPickerModel(
            title: "Build & Run \(subject) on",
            simulators: ordered.map { LaunchPickerModel.SimulatorOption(id: $0.element.id, title: title($0.element, runtime: runtime($0.element.id))) },
            selectedID: targetID,
            launch: config.map {
                IdentityPanelMapper.launch(config: $0, settings: settings, actualDeviceID: identity?.lastDeviceID, savedDeviceIDs: savedDeviceIDs, aliases: aliases)
            },
            cleanInstallNote: config == nil ? nil : IdentityPanelMapper.cleanInstallNote(needsCleanInstall: needsCleanInstall, cleanInstallIsOn: cleanInstallIsOn),
            runTitle: willCleanInstall ? "Reinstall & Run" : "Build & Run",
            runTint: willCleanInstall ? .orange : .green,
            canRun: targetID != nil && buildIsRunning == false
        )
    }

    private static func rank(_ simulator: Simulator) -> Int {
        if simulator.state == .booted { return 0 }
        return simulator.isFavorite ? 1 : 2
    }

    private static func title(_ simulator: Simulator, runtime: String?) -> String {
        [simulator.name, runtime, simulator.state == .booted ? "booted" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
