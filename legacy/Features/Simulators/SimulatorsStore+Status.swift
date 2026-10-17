import Foundation

extension SimulatorsStore {
    func refreshStatuses() {
        guard let script = config.config.simulators?.statusScript, let path = config.resolveScript(script) else {
            clearStatuses()
            return
        }
        let wanted = simulators.filter { $0.isBooted || $0.isFavorite || $0.id == targetID }
        for simulator in wanted {
            refreshStatus(of: simulator, script: path)
        }
    }

    func refreshStatus(of simulator: SimulatorInfo) {
        guard let script = config.config.simulators?.statusScript, let path = config.resolveScript(script) else { return }
        refreshStatus(of: simulator, script: path)
    }

    private func refreshStatus(of simulator: SimulatorInfo, script: String) {
        statusTasks[simulator.id]?.cancel()
        let context = ActionContextBuilder(session: session, config: config).make(
            configDir: (script as NSString).deletingLastPathComponent,
            item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name),
            inputs: [:]
        )
        let folder = session.project?.path ?? NSHomeDirectory()
        statusTasks[simulator.id] = Task { [weak self] in
            guard let self else { return }
            let status = await readStatus(script: script, environment: context.environment, folder: folder)
            guard Task.isCancelled == false else { return }
            setStatus(status, for: simulator.id)
            statusTasks[simulator.id] = nil
        }
    }

    private func readStatus(script: String, environment: [String: String], folder: String) async -> SimulatorStatus? {
        do {
            guard let text = try await provider.statusLine(script: script, environment: environment, folder: folder) else { return nil }
            return SimulatorStatus(text: text, isFailure: false)
        } catch {
            return SimulatorStatus(text: error.localizedDescription, isFailure: true)
        }
    }
}
