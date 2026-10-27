import DevHubDomain
import Foundation

package final class SpySimulatorSettingsRepository: SimulatorSettingsRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case apply(SimulatorSetting, udid: String)
        case screenshot(udid: String, path: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _error: (any Error)? = nil

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

    private func record(_ call: Call) throws {
        try lock.withLock {
            _calls.append(call)
            if let _error { throw _error }
        }
    }
}
