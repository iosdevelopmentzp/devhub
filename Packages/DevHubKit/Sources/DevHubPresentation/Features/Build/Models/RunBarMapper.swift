import Foundation
import DevHubDomain
import DevHubUI

enum RunBarMapper {

    static func model(
        state: BuildState,
        target: Simulator?,
        runtime: String?,
        identity: AppIdentity?,
        identitySettings: SimulatorIdentitySettings?,
        savedDeviceIDs: [String],
        deviceIDAliases: [String: String],
        mockState: MockServerState?,
        isApplying: Bool,
        config: DeviceIdentityConfig?,
        hasLog: Bool,
        isLoadingSimulators: Bool
    ) -> RunBarModel {
        RunBarModel(
            targetLabel: "Target",
            target: target.map {
                targetModel(
                    for: $0,
                    runtime: runtime,
                    identity: identity,
                    settings: identitySettings ?? SimulatorIdentitySettings(hasApplied: false),
                    savedDeviceIDs: savedDeviceIDs,
                    deviceIDAliases: deviceIDAliases,
                    mockState: mockState,
                    isApplying: isApplying,
                    config: config,
                    cleanInstallIsOn: state.cleanInstall
                )
            },
            noTargetText: "No simulator selected",
            progress: progress(state.phase),
            outcome: outcome(state.phase, targetName: target?.name),
            isRunning: state.isRunning,
            canRun: target != nil,
            canShowLog: hasLog,
            canRefreshSimulators: isLoadingSimulators == false
        )
    }

    private static func targetModel(
        for simulator: Simulator,
        runtime: String?,
        identity: AppIdentity?,
        settings: SimulatorIdentitySettings,
        savedDeviceIDs: [String],
        deviceIDAliases: [String: String],
        mockState: MockServerState?,
        isApplying: Bool,
        config: DeviceIdentityConfig?,
        cleanInstallIsOn: Bool
    ) -> RunBarModel.Target {
        let installed = identity.flatMap { $0.isInstalled ? $0 : nil }
        let hasConfig = config != nil
        let needsCleanInstall = IdentityPanelMapper.needsCleanInstall(identity: identity, settings: settings, savedDeviceIDs: savedDeviceIDs)
        return RunBarModel.Target(
            id: simulator.id,
            name: simulator.name,
            icon: SimulatorRowMapper.kindIcon(simulator.kind),
            runtimeTag: runtime.map { TagModel($0) },
            identity: hasConfig ? installed.map { IdentityPanelMapper.summary(for: $0, settings: settings, aliases: deviceIDAliases, mockState: mockState, isApplying: isApplying) } : nil,
            identityMissingText: hasConfig && installed == nil ? "App not installed on this simulator" : nil,
            launch: config.map { IdentityPanelMapper.launch(config: $0, settings: settings, actualDeviceID: identity?.lastDeviceID, savedDeviceIDs: savedDeviceIDs, aliases: deviceIDAliases) },
            cleanInstallNote: hasConfig ? IdentityPanelMapper.cleanInstallNote(needsCleanInstall: needsCleanInstall, cleanInstallIsOn: cleanInstallIsOn) : nil
        )
    }

    private static func progress(_ phase: BuildState.Phase) -> RunBarModel.Progress? {
        guard case .running(let step, let value) = phase else { return nil }
        return RunBarModel.Progress(step: step, value: value)
    }

    private static func outcome(_ phase: BuildState.Phase, targetName: String?) -> RunBarModel.Outcome? {
        switch phase {
        case .succeeded(let date):
            RunBarModel.Outcome(tint: .green, text: "Launched on \(targetName ?? "simulator") · \(date.relativeDescription)")
        case .failed(let message):
            RunBarModel.Outcome(tint: .red, text: message)
        case .idle, .running:
            nil
        }
    }
}
