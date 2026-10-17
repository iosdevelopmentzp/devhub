import DevHubDomain
import Foundation

package final class SpyDeviceIdentityRepository: DeviceIdentityRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case read(udid: String, config: DeviceIdentityConfig)
        case setEnvironment(String, udid: String, config: DeviceIdentityConfig)
        case cleanInstall(udid: String, config: DeviceIdentityConfig, fallbackAppPath: String?)
        case launch(udid: String, config: DeviceIdentityConfig, deviceID: String?, waitForDebugger: Bool, environment: [String: String])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _launchArguments: [[String]] = []
    private var _readResult: AppIdentity = .notInstalled
    private var _setEnvironmentError: (any Error)? = nil
    private var _cleanInstallError: (any Error)? = nil
    private var _launchResult: Result<Int32?, any Error> = .success(nil)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var readResult: AppIdentity {
        get { lock.withLock { _readResult } }
        set { lock.withLock { _readResult = newValue } }
    }

    package var setEnvironmentError: (any Error)? {
        get { lock.withLock { _setEnvironmentError } }
        set { lock.withLock { _setEnvironmentError = newValue } }
    }

    package var cleanInstallError: (any Error)? {
        get { lock.withLock { _cleanInstallError } }
        set { lock.withLock { _cleanInstallError = newValue } }
    }

    package var launchResult: Result<Int32?, any Error> {
        get { lock.withLock { _launchResult } }
        set { lock.withLock { _launchResult = newValue } }
    }

    package func read(udid: String, config: DeviceIdentityConfig) async -> AppIdentity {
        record(.read(udid: udid, config: config)) { _readResult }
    }

    package func setEnvironment(_ environment: String, udid: String, config: DeviceIdentityConfig) async throws {
        let error = record(.setEnvironment(environment, udid: udid, config: config)) { _setEnvironmentError }
        if let error { throw error }
    }

    package func cleanInstall(udid: String, config: DeviceIdentityConfig, fallbackAppPath: String?) async throws {
        let error = record(.cleanInstall(udid: udid, config: config, fallbackAppPath: fallbackAppPath)) { _cleanInstallError }
        if let error { throw error }
    }

    package func launch(udid: String, config: DeviceIdentityConfig, deviceID: String?, waitForDebugger: Bool, environment: [String: String], arguments: [String]) async throws -> Int32? {
        lock.withLock { _launchArguments.append(arguments) }
        return try record(.launch(udid: udid, config: config, deviceID: deviceID, waitForDebugger: waitForDebugger, environment: environment)) { try _launchResult.get() }
    }

    package var launchArguments: [[String]] {
        lock.withLock { _launchArguments }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
