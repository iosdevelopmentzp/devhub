import DevHubDomain
import Foundation

package final class SpySimulatorSettingsRepository: SimulatorSettingsRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case apply(SimulatorSetting, udid: String)
        case screenshot(udid: String, path: String)
        case record(udid: String, path: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _error: (any Error)? = nil
    private var recordings: [AsyncStream<Void>.Continuation] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var error: (any Error)? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    package func apply(_ setting: SimulatorSetting, udid: String) async throws {
        try record(.apply(setting, udid: udid))
    }

    package func screenshot(udid: String, to path: String) async throws {
        try record(.screenshot(udid: udid, path: path))
    }

    package func record(udid: String, to path: String, onStarted: @escaping @Sendable () -> Void) async throws {
        try record(.record(udid: udid, path: path))
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        lock.withLock { recordings.append(continuation) }
        onStarted()
        for await _ in stream {}
    }

    package func finishRecordings() {
        lock.withLock { recordings }.forEach { $0.finish() }
    }

    private func record(_ call: Call) throws {
        try lock.withLock {
            _calls.append(call)
            if let _error { throw _error }
        }
    }
}
