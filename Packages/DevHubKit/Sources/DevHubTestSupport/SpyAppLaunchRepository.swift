import DevHubDomain
import Foundation

package final class SpyAppLaunchRepository: AppLaunchRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?)
        case cleanInstall(udid: String, bundleID: String, fallbackAppPath: String?)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _inspectResult: InstalledApp = .notInstalled
    private var _cleanInstallError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var inspectResult: InstalledApp {
        get { lock.withLock { _inspectResult } }
        set { lock.withLock { _inspectResult = newValue } }
    }

    package var cleanInstallError: (any Error)? {
        get { lock.withLock { _cleanInstallError } }
        set { lock.withLock { _cleanInstallError = newValue } }
    }

    package func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?) async -> InstalledApp {
        record(.inspect(udid: udid, bundleID: bundleID, identity: identity, storage: storage)) { _inspectResult }
    }

    package func cleanInstall(udid: String, bundleID: String, fallbackAppPath: String?) async throws {
        let error = record(.cleanInstall(udid: udid, bundleID: bundleID, fallbackAppPath: fallbackAppPath)) { _cleanInstallError }
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
