import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class LogsStore {
    private(set) var streams: [LogStream] = []
    var selectedID: Simulator.ID? {
        didSet {
            guard selectedID != oldValue else { return }
            store.set(selectedID, forKey: Keys.selected)
        }
    }

    @ObservationIgnored private let repository: AppLogRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let identity: any IdentityLookup
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var tasks: [Simulator.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var runs: [Simulator.ID: UUID] = [:]
    @ObservationIgnored private var incoming: [Simulator.ID: [AppLogLine]] = [:]
    @ObservationIgnored private var flushTask: Task<Void, Never>?

    private static let batchInterval: Duration = .milliseconds(150)

    init(repository: AppLogRepository, session: ProjectSession, config: ConfigStore, simulators: any SimulatorLookup, identity: any IdentityLookup, activity: ActivityLog, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.config = config
        self.simulators = simulators
        self.identity = identity
        self.activity = activity
        self.store = store
        streams = (store.decode([LogStreamSettings].self, forKey: Keys.streams) ?? []).map(LogStream.init(settings:))
        selectedID = store.string(forKey: Keys.selected) ?? streams.first?.id
    }

    var selected: LogStream? {
        streams.first { $0.id == selectedID } ?? streams.first
    }

    var availableSimulators: [Simulator] {
        simulators.all.filter { simulator in
            simulator.state == .booted && streams.contains { $0.id == simulator.id } == false
        }
    }

    func prepare(defaultUDID: Simulator.ID?) {
        guard streams.isEmpty, let defaultUDID, let simulator = simulators.simulator(id: defaultUDID) else { return }
        add(simulator)
    }

    func stream(on udid: Simulator.ID) {
        guard let simulator = simulators.simulator(id: udid) else { return }
        add(simulator)
        start(udid)
    }

    func start(_ id: Simulator.ID) {
        guard let stream = stream(id), stream.isRunning == false else { return }
        let token = UUID()
        runs[id] = token
        update(id) {
            $0.isRunning = true
            $0.error = nil
        }
        tasks[id] = Task { [weak self] in
            guard let self else { return }
            await run(id, token: token)
        }
    }

    func stop(_ id: Simulator.ID) {
        runs[id] = nil
        tasks[id]?.cancel()
        tasks[id] = nil
        drain()
        update(id) { $0.isRunning = false }
    }

    func remove(_ id: Simulator.ID) {
        stop(id)
        incoming[id] = nil
        streams.removeAll { $0.id == id }
        if selectedID == id {
            selectedID = streams.first?.id
        }
        save()
    }

    func clear(_ id: Simulator.ID) {
        incoming[id] = nil
        update(id) { $0.clear() }
    }

    func setPaused(_ paused: Bool, for id: Simulator.ID) {
        drain()
        update(id) { $0.setPaused(paused) }
    }

    func setLevel(_ level: AppLogLine.Level, for id: Simulator.ID) {
        update(id) { $0.minimumLevel = level }
        save()
    }

    func setProcess(_ process: String, for id: Simulator.ID) {
        update(id) { $0.process = process }
        save()
    }

    func setSubsystem(_ subsystem: String, for id: Simulator.ID) {
        update(id) { $0.subsystem = subsystem }
        save()
    }

    private func add(_ simulator: Simulator) {
        if streams.contains(where: { $0.id == simulator.id }) == false {
            let logs = config.config.logs
            streams.append(LogStream(
                id: simulator.id,
                name: simulator.name,
                process: logs?.process ?? "",
                subsystem: logs?.subsystem ?? "",
                minimumLevel: .debug
            ))
            save()
        }
        selectedID = simulator.id
    }

    private func run(_ id: Simulator.ID, token: UUID) async {
        guard await prepareFilter(id) else {
            finish(id, token: token, error: nil)
            return
        }
        guard runs[id] == token, let stream = stream(id) else { return }
        startFlushing()
        do {
            for try await line in repository.stream(udid: id, filter: stream.filter) {
                incoming[id, default: []].append(line)
            }
            finish(id, token: token, error: nil)
        } catch is CancellationError {
            finish(id, token: token, error: nil)
        } catch {
            activity.log("Log stream stopped", detail: error.localizedDescription, outcome: .failure)
            finish(id, token: token, error: error.localizedDescription)
        }
    }

    private func prepareFilter(_ id: Simulator.ID) async -> Bool {
        guard let stream = stream(id) else { return false }
        guard stream.filter.isEmpty else { return true }
        let project = session.selectedProject
        let name = await repository.executableName(udid: id, bundleID: identity.bundleID(for: id)) ?? project.scheme
        guard name.trimmed.isEmpty == false else {
            let message = "No process name. Type one in the Process field."
            activity.log("Log stream", detail: message, outcome: .failure)
            update(id) { $0.error = message }
            return false
        }
        update(id) { $0.process = name }
        save()
        return true
    }

    private func finish(_ id: Simulator.ID, token: UUID, error: String?) {
        guard runs[id] == token else { return }
        runs[id] = nil
        tasks[id] = nil
        drain()
        update(id) {
            $0.isRunning = false
            if let error {
                $0.error = error
            }
        }
    }

    private func startFlushing() {
        guard flushTask == nil else { return }
        flushTask = Task { [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(for: Self.batchInterval)
                guard let self else { return }
                drain()
                if tasks.isEmpty, incoming.isEmpty {
                    flushTask = nil
                    return
                }
            }
        }
    }

    private func drain() {
        let batches = incoming
        incoming = [:]
        for (id, lines) in batches where lines.isEmpty == false {
            update(id) { $0.receive(lines) }
        }
    }

    private func stream(_ id: Simulator.ID) -> LogStream? {
        streams.first { $0.id == id }
    }

    private func update(_ id: Simulator.ID, _ change: (inout LogStream) -> Void) {
        guard let index = streams.firstIndex(where: { $0.id == id }) else { return }
        change(&streams[index])
    }

    private func save() {
        store.encode(streams.map(\.settings), forKey: Keys.streams)
    }

    private enum Keys {
        static let streams = "logs.streams"
        static let selected = "logs.selected"
    }
}
