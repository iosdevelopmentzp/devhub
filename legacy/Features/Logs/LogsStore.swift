import Foundation
import Observation

@MainActor
@Observable
final class LogsStore {
    static let batchInterval: Duration = .milliseconds(150)

    private(set) var streams: [LogStream] = []
    var selectedID: String?

    @ObservationIgnored private let provider: AppLogProviding
    @ObservationIgnored private let simulators: SimulatorsStore
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let preferences: AppPreferences
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var runs: [String: UUID] = [:]
    @ObservationIgnored private var incoming: [String: [LogLine]] = [:]
    @ObservationIgnored private var flushTask: Task<Void, Never>?

    init(provider: AppLogProviding, simulators: SimulatorsStore, config: ConfigStore, activity: ActivityLog, preferences: AppPreferences) {
        self.provider = provider
        self.simulators = simulators
        self.config = config
        self.activity = activity
        self.preferences = preferences
        let saved = preferences.value([SavedLogStream].self, for: .logStreams) ?? []
        streams = saved.map(LogStream.init(saved:))
        selectedID = streams.first?.id
    }

    var selected: LogStream? {
        streams.first { $0.id == selectedID } ?? streams.first
    }

    var availableSimulators: [SimulatorInfo] {
        simulators.simulators.filter { simulator in
            simulator.state == .booted && streams.contains { $0.id == simulator.id } == false
        }
    }

    func isBooted(_ simulatorID: String) -> Bool {
        simulators.simulators.first { $0.id == simulatorID }?.state == .booted
    }

    func refreshSimulators() async {
        await simulators.refresh()
    }

    func startStream(udid: String, name: String) {
        if streams.contains(where: { $0.id == udid }) == false {
            let logs = config.config.logs
            streams.append(LogStream(
                simulatorID: udid,
                name: name,
                process: logs?.process ?? "",
                subsystem: logs?.subsystem ?? "",
                level: .all
            ))
            save()
        }
        selectedID = udid
        start(udid)
    }

    func start(_ id: String) {
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

    func stop(_ id: String) {
        runs[id] = nil
        tasks[id]?.cancel()
        tasks[id] = nil
        update(id) { $0.isRunning = false }
    }

    func remove(_ id: String) {
        stop(id)
        incoming[id] = nil
        streams.removeAll { $0.id == id }
        if selectedID == id {
            selectedID = streams.first?.id
        }
        save()
    }

    func clear(_ id: String) {
        incoming[id] = nil
        update(id) { $0.clear() }
    }

    func togglePause(_ id: String) {
        update(id) {
            if $0.isPaused {
                $0.resume()
            } else {
                $0.isPaused = true
            }
        }
    }

    func setLevel(_ level: LogLevelFilter, for id: String) {
        update(id) { $0.level = level }
        save()
    }

    func setProcess(_ process: String, for id: String) {
        update(id) { $0.process = process }
        save()
    }

    func setSubsystem(_ subsystem: String, for id: String) {
        update(id) { $0.subsystem = subsystem }
        save()
    }

    private func run(_ id: String, token: UUID) async {
        guard await prepareFilter(id) else {
            finish(id, token: token, error: nil)
            return
        }
        guard runs[id] == token, let stream = stream(id) else { return }
        startFlushing()
        do {
            for try await line in provider.stream(simulatorID: id, filter: stream.filter) {
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

    private func prepareFilter(_ id: String) async -> Bool {
        guard let stream = stream(id) else { return false }
        if stream.process.isEmpty == false || stream.subsystem.isEmpty == false {
            return true
        }
        guard let bundleID = config.effective?.bundleID else {
            fail(id, "No process name. Type one in the Process field.")
            return false
        }
        do {
            let name = try await simulators.executableName(simulatorID: id, bundleID: bundleID)
            update(id) { $0.process = name }
            save()
            return true
        } catch {
            fail(id, "Could not find the app executable: \(error.localizedDescription) Type a process name instead.")
            return false
        }
    }

    private func fail(_ id: String, _ message: String) {
        activity.log("Log stream", detail: message, outcome: .failure)
        update(id) { $0.error = message }
    }

    private func finish(_ id: String, token: UUID, error: String?) {
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
        incoming.removeAll()
        for (id, lines) in batches where lines.isEmpty == false {
            update(id) { $0.receive(lines) }
        }
    }

    private func stream(_ id: String) -> LogStream? {
        streams.first { $0.id == id }
    }

    private func update(_ id: String, _ change: (inout LogStream) -> Void) {
        guard let index = streams.firstIndex(where: { $0.id == id }) else { return }
        change(&streams[index])
    }

    private func save() {
        preferences.setValue(streams.map(\.saved), for: .logStreams)
    }
}
