import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class LogsStore {
    private(set) var lines: [AppLogLine] = []
    private(set) var droppedLines = 0
    private(set) var streamingUDID: Simulator.ID?
    private(set) var streamingProcess: String?
    private(set) var error: String?
    var selectedUDID: Simulator.ID? {
        didSet {
            guard selectedUDID != oldValue else { return }
            store.set(selectedUDID, forKey: Keys.simulator)
        }
    }
    var process = ""
    var minimumLevel: AppLogLine.Level = .debug {
        didSet {
            guard minimumLevel != oldValue else { return }
            store.set(minimumLevel.rawValue, forKey: Keys.level)
        }
    }
    var isPaused = false {
        didSet {
            guard isPaused == false else { return }
            flush()
        }
    }

    @ObservationIgnored private let repository: AppLogRepository
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private var pending: [AppLogLine] = []
    @ObservationIgnored private var flushTask: Task<Void, Never>?
    @ObservationIgnored private let store: any KeyValueStore

    private static let maxLines = 5_000

    init(repository: AppLogRepository, session: ProjectSession, store: any KeyValueStore) {
        self.repository = repository
        self.session = session
        self.store = store
        selectedUDID = store.string(forKey: Keys.simulator)
        minimumLevel = AppLogLine.Level(rawValue: store.integer(forKey: Keys.level)) ?? .debug
    }

    var isStreaming: Bool {
        streamingUDID != nil
    }

    var pendingCount: Int {
        pending.count
    }

    var visibleLines: [AppLogLine] {
        lines.filter { $0.level >= minimumLevel }
    }

    func prepare(defaultUDID: Simulator.ID?, knownUDIDs: Set<Simulator.ID>) async {
        if let selectedUDID, knownUDIDs.isEmpty == false, knownUDIDs.contains(selectedUDID) == false {
            self.selectedUDID = nil
        }
        if selectedUDID == nil {
            selectedUDID = defaultUDID
        }
        guard process.isEmpty, let udid = selectedUDID else { return }
        process = await repository.executableName(udid: udid, bundleID: session.selectedProject.bundleID) ?? session.selectedProject.scheme
    }

    func stream(on udid: Simulator.ID) {
        selectedUDID = udid
        Task {
            if process.trimmed.isEmpty {
                process = await repository.executableName(udid: udid, bundleID: session.selectedProject.bundleID) ?? session.selectedProject.scheme
            }
            start()
        }
    }

    func start() {
        guard let udid = selectedUDID, process.trimmed.isEmpty == false else { return }
        stop()
        let name = process.trimmed
        streamingUDID = udid
        streamingProcess = name
        error = nil
        streamTask = Task { [weak self] in
            guard let self else { return }
            do {
                for try await line in repository.stream(udid: udid, process: name) {
                    receive(line)
                }
            } catch is CancellationError {
            } catch {
                self.error = error.localizedDescription
            }
            if streamingUDID == udid {
                streamingUDID = nil
                streamingProcess = nil
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        streamingUDID = nil
        streamingProcess = nil
        flush()
    }

    func clear() {
        lines = []
        pending = []
        droppedLines = 0
    }

    private func receive(_ line: AppLogLine) {
        pending.append(line)
        guard isPaused == false, flushTask == nil else { return }
        flushTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            self?.flushTask = nil
            self?.flush()
        }
    }

    private func flush() {
        guard isPaused == false, pending.isEmpty == false else { return }
        lines.append(contentsOf: pending)
        pending = []
        let overflow = lines.count - Self.maxLines
        if overflow > 0 {
            lines.removeFirst(overflow)
            droppedLines += overflow
        }
    }

    private enum Keys {
        static let simulator = "logs.simulator"
        static let level = "logs.level"
    }
}
