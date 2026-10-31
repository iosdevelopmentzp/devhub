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
        isLoadingSimulators: Bool
    ) -> RunBarModel {
        RunBarModel(
            targetLabel: "Target",
            target: target.map { targetModel(for: $0, runtime: runtime, identity: identity, mockState: mockState, cleanInstallIsOn: state.cleanInstall) },
            noTargetText: "No simulator selected",
            progress: progress(state.phase),
            outcome: outcome(state.phase, targetName: target?.name, scheme: state.scheme),
            isRunning: state.isRunning,
            canRun: target != nil,
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
            identityMissingText: identity.flatMap { $0.isInstalled ? nil : "App not installed on this simulator" },
            launch: identity.map { IdentityPanelMapper.launch(context: $0) },
            cleanInstallNote: identity.map { IdentityPanelMapper.cleanInstallNote(context: $0, cleanInstallIsOn: cleanInstallIsOn) }
        )
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
                text: launched ? "Launched on \(targetName ?? "simulator") · \(date.relativeDescription)" : "Built \(scheme), not launched · \(date.relativeDescription)"
            )
        case .failed(let message):
            RunBarModel.Outcome(tint: .red, text: message)
        case .idle, .running:
            nil
        }
    }
}
