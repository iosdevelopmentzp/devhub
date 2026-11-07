import Foundation
import DevHubDomain
import DevHubUI

enum RunBarMapper {

    static func model(
        state: BuildState,
        target: Simulator?,
        runtime: String?,
        identity: IdentityContext?,
        mockState: MockServerState?,
        hasLog: Bool,
        isLoadingSimulators: Bool,
        isCommandProject: Bool = false
    ) -> RunBarModel {
        let isPhysical = target?.isPhysical == true
        return RunBarModel(
            targetLabel: "Target",
            target: target.map { targetModel(for: $0, runtime: runtime, identity: identity, mockState: mockState, cleanInstallIsOn: state.cleanInstall) },
            noTargetText: "No simulator or device selected",
            progress: progress(state.phase),
            outcome: outcome(state.phase, targetName: target?.name, scheme: state.scheme),
            isRunning: state.isRunning,
            canRun: target != nil,
            canAttach: target != nil && isCommandProject == false,
            runHint: isPhysical ? "Build and launch on the target device (⌘R)" : "Build and launch on the target simulator (⌘R)",
            attachHint: attachHint(isCommandProject: isCommandProject, isPhysical: isPhysical),
            canShowLog: hasLog,
            canRefreshSimulators: isLoadingSimulators == false
        )
    }

    private static func targetModel(
        for simulator: Simulator,
        runtime: String?,
        identity: IdentityContext?,
        mockState: MockServerState?,
        cleanInstallIsOn: Bool
    ) -> RunBarModel.Target {
        RunBarModel.Target(
            id: simulator.id,
            name: simulator.name,
            icon: SimulatorRowMapper.kindIcon(simulator.kind),
            runtimeTag: runtime.map { TagModel($0) },
            identity: identity.flatMap { $0.isInstalled ? IdentityPanelMapper.summary(context: $0, mockState: mockState) : nil },
            identityMissingText: identity.flatMap { $0.isInstalled ? nil : (simulator.isPhysical ? "App not installed on this device" : "App not installed on this simulator") },
            launch: identity.map { IdentityPanelMapper.launch(context: $0) },
            cleanInstallNote: identity.map { IdentityPanelMapper.cleanInstallNote(context: $0, cleanInstallIsOn: cleanInstallIsOn) }
        )
    }

    private static func attachHint(isCommandProject: Bool, isPhysical: Bool) -> String {
        if isCommandProject { return "Run & Attach needs an Xcode project. This project builds with its commands." }
        if isPhysical { return "Build, launch stopped with devicectl --start-stopped and attach Xcode (⇧⌘R). Xcode's console stays empty for an attached process." }
        return "Build, launch frozen with --wait-for-debugger and attach Xcode (⇧⌘R). Xcode's console stays empty for an attached process."
    }

    private static func progress(_ phase: BuildState.Phase) -> RunBarModel.Progress? {
        guard case .running(let step, let value) = phase else { return nil }
        return RunBarModel.Progress(step: step, value: value)
    }

    private static func outcome(_ phase: BuildState.Phase, targetName: String?, scheme: String) -> RunBarModel.Outcome? {
        switch phase {
        case .succeeded(let date, let launched):
            RunBarModel.Outcome(
                tint: .green,
                text: launched ? "Launched on \(targetName ?? "the target") · \(date.relativeDescription)" : "Built \(scheme), not launched · \(date.relativeDescription)"
            )
        case .failed(let message):
            RunBarModel.Outcome(tint: .red, text: message)
        case .idle, .running:
            nil
        }
    }
}
