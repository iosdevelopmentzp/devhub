import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class SimulatorStatusStore {
    private(set) var statuses: [Simulator.ID: SimulatorStatus] = [:]

    @ObservationIgnored private let readStatus: ReadSimulatorStatusUseCase
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let build: any BuildLookup
    @ObservationIgnored private var tasks: [Simulator.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(readStatus: ReadSimulatorStatusUseCase, config: ConfigStore, session: ProjectSession, simulators: any SimulatorLookup, build: any BuildLookup, events: AppEvents) {
        self.readStatus = readStatus
        self.config = config
        self.session = session
        self.simulators = simulators
        self.build = build
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .configChanged, .projectChanged, .refreshRequested(.simulators):
                reloadAll()
            case .simulatorsChanged:
                loadMissing()
            case let .appLaunched(id), let .buildFinished(id, _):
                guard let simulator = simulators.simulator(id: id) else { return }
                read(simulator)
            default:
                break
            }
        }
    }

    func loadMissing() {
        for simulator in wanted where statuses[simulator.id] == nil && tasks[simulator.id] == nil {
            read(simulator)
        }
    }

    func reloadAll() {
        tasks.values.forEach { $0.cancel() }
        tasks = [:]
        statuses = [:]
        loadMissing()
    }

    private var script: String? {
        guard session.hasProject else { return nil }
        return config.config.simulators?.statusScript
    }

    private var wanted: [Simulator] {
        guard script != nil else { return [] }
        let targetID = build.target?.id
        return simulators.all.filter { $0.state == .booted || $0.isFavorite || $0.id == targetID }
    }

    private func read(_ simulator: Simulator) {
        guard let script else { return }
        tasks[simulator.id]?.cancel()
        let request = SimulatorStatusRequest(
            script: script,
            layers: config.resolved.layers,
            projectPath: session.selectedProject.path,
            environment: environment(for: simulator)
        )
        tasks[simulator.id] = Task { [weak self] in
            guard let self else { return }
            let status = await status(for: request)
            guard Task.isCancelled == false else { return }
            if statuses[simulator.id] != status {
                statuses[simulator.id] = status
            }
            tasks[simulator.id] = nil
        }
    }

    private func status(for request: SimulatorStatusRequest) async -> SimulatorStatus? {
        do {
            return try await readStatus.execute(request).map { SimulatorStatus(text: $0, isFailure: false) }
        } catch {
            return SimulatorStatus(text: error.localizedDescription, isFailure: true)
        }
    }

    private func environment(for simulator: Simulator) -> [String: String] {
        let project = session.selectedProject
        let path = ProjectPath(project.path).expanded
        return ActionContextPolicy.make(ActionContextInputs(
            projectPath: path,
            projectName: project.name,
            checkoutPath: path,
            branch: "",
            effective: config.effective(detectedSchemes: build.schemeOptions, detectedBaseBranch: nil),
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            appPath: build.lastBuiltAppPath() ?? "",
            configDir: "",
            item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name, rowID: simulator.id),
            inputs: [:],
            version: ""
        )).environment
    }
}
