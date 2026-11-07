import DevHubDomain
import Foundation

package final class SpyDeviceRepository: DeviceRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case list
        case install(udid: String, appPath: String)
        case uninstall(udid: String, bundleID: String)
        case launch(udid: String, bundleID: String, environment: [String: String])
        case launchStopped(udid: String, bundleID: String, environment: [String: String])
        case inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?, localAppPath: String?)
        case writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _launchArguments: [[String]] = []
    private var _listResult: Result<[Simulator], any Error> = .success([])
    private var _installError: (any Error)? = nil
    private var _uninstallError: (any Error)? = nil
    private var _launchResult: Result<Int32?, any Error> = .success(nil)
    private var _inspectResult: InstalledApp = .notInstalled
    private var _writeDefaultsError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var launchArguments: [[String]] {
        lock.withLock { _launchArguments }
    }

    package var listResult: Result<[Simulator], any Error> {
        get { lock.withLock { _listResult } }
        set { lock.withLock { _listResult = newValue } }
    }

    package var installError: (any Error)? {
        get { lock.withLock { _installError } }
        set { lock.withLock { _installError = newValue } }
    }

    package var uninstallError: (any Error)? {
        get { lock.withLock { _uninstallError } }
        set { lock.withLock { _uninstallError = newValue } }
    }

    package var launchResult: Result<Int32?, any Error> {
        get { lock.withLock { _launchResult } }
        set { lock.withLock { _launchResult = newValue } }
    }

    package var inspectResult: InstalledApp {
        get { lock.withLock { _inspectResult } }
        set { lock.withLock { _inspectResult = newValue } }
    }

    package var writeDefaultsError: (any Error)? {
        get { lock.withLock { _writeDefaultsError } }
        set { lock.withLock { _writeDefaultsError = newValue } }
    }

    package func list() async throws -> [Simulator] {
        try record(.list) { try _listResult.get() }
    }

    package func install(udid: String, appPath: String) async throws {
        let error = record(.install(udid: udid, appPath: appPath)) { _installError }
        if let error { throw error }
    }

    package func uninstall(udid: String, bundleID: String) async throws {
        let error = record(.uninstall(udid: udid, bundleID: bundleID)) { _uninstallError }
        if let error { throw error }
    }

    package func launch(udid: String, bundleID: String, environment: [String: String], arguments: [String], startStopped: Bool) async throws -> Int32? {
        lock.withLock { _launchArguments.append(arguments) }
        let call: Call = startStopped ? .launchStopped(udid: udid, bundleID: bundleID, environment: environment) : .launch(udid: udid, bundleID: bundleID, environment: environment)
        return try record(call) { try _launchResult.get() }
    }

    package func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?, localAppPath: String?) async -> InstalledApp {
        record(.inspect(udid: udid, bundleID: bundleID, identity: identity, storage: storage, localAppPath: localAppPath)) { _inspectResult }
    }

    package func writeDefaults(udid: String, bundleID: String, defaults: [ProfileDefault]) async throws {
        let error = record(.writeDefaults(udid: udid, bundleID: bundleID, defaults: defaults)) { _writeDefaultsError }
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
