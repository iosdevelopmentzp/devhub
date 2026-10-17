import DevHubDomain
import Foundation

package final class SpySimulatorRepository: SimulatorRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case list
        case boot(udid: String)
        case shutdown(udid: String)
        case erase(udid: String)
        case openInSimulatorApp(udid: String)
        case uninstallUserApps(udid: String, wasBooted: Bool)
        case installedAppCounts(udids: [String])
        case uninstall(udid: String, bundleID: String, wasBooted: Bool)
        case install(udid: String, appPath: String)
        case uninstallQuietly(udid: String, bundleID: String)
        case resetKeychain(udid: String)
        case launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String])
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _listResult: Result<[SimulatorGroup], any Error> = .success([])
    private var _bootError: (any Error)? = nil
    private var _shutdownError: (any Error)? = nil
    private var _eraseError: (any Error)? = nil
    private var _openInSimulatorAppError: (any Error)? = nil
    private var _uninstallUserAppsResult: Result<[String], any Error> = .success([])
    private var _installedAppCountsResult: [String: Int] = [:]
    private var _uninstallError: (any Error)? = nil
    private var _installError: (any Error)? = nil
    private var _resetKeychainError: (any Error)? = nil
    private var _launchResult: Result<Int32?, any Error> = .success(nil)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var listResult: Result<[SimulatorGroup], any Error> {
        get { lock.withLock { _listResult } }
        set { lock.withLock { _listResult = newValue } }
    }

    package var bootError: (any Error)? {
        get { lock.withLock { _bootError } }
        set { lock.withLock { _bootError = newValue } }
    }

    package var shutdownError: (any Error)? {
        get { lock.withLock { _shutdownError } }
        set { lock.withLock { _shutdownError = newValue } }
    }

    package var eraseError: (any Error)? {
        get { lock.withLock { _eraseError } }
        set { lock.withLock { _eraseError = newValue } }
    }

    package var openInSimulatorAppError: (any Error)? {
        get { lock.withLock { _openInSimulatorAppError } }
        set { lock.withLock { _openInSimulatorAppError = newValue } }
    }

    package var uninstallUserAppsResult: Result<[String], any Error> {
        get { lock.withLock { _uninstallUserAppsResult } }
        set { lock.withLock { _uninstallUserAppsResult = newValue } }
    }

    package var installedAppCountsResult: [String: Int] {
        get { lock.withLock { _installedAppCountsResult } }
        set { lock.withLock { _installedAppCountsResult = newValue } }
    }

    package var uninstallError: (any Error)? {
        get { lock.withLock { _uninstallError } }
        set { lock.withLock { _uninstallError = newValue } }
    }

    package var installError: (any Error)? {
        get { lock.withLock { _installError } }
        set { lock.withLock { _installError = newValue } }
    }

    package var resetKeychainError: (any Error)? {
        get { lock.withLock { _resetKeychainError } }
        set { lock.withLock { _resetKeychainError = newValue } }
    }

    package var launchResult: Result<Int32?, any Error> {
        get { lock.withLock { _launchResult } }
        set { lock.withLock { _launchResult = newValue } }
    }

    package func list() async throws -> [SimulatorGroup] {
        try record(.list) { try _listResult.get() }
    }

    package func boot(udid: String) async throws {
        let error = record(.boot(udid: udid)) { _bootError }
        if let error { throw error }
    }

    package func shutdown(udid: String) async throws {
        let error = record(.shutdown(udid: udid)) { _shutdownError }
        if let error { throw error }
    }

    package func erase(udid: String) async throws {
        let error = record(.erase(udid: udid)) { _eraseError }
        if let error { throw error }
    }

    package func openInSimulatorApp(udid: String) async throws {
        let error = record(.openInSimulatorApp(udid: udid)) { _openInSimulatorAppError }
        if let error { throw error }
    }

    package func uninstallUserApps(udid: String, wasBooted: Bool) async throws -> [String] {
        try record(.uninstallUserApps(udid: udid, wasBooted: wasBooted)) { try _uninstallUserAppsResult.get() }
    }

    package func installedAppCounts(udids: [String]) async -> [String: Int] {
        record(.installedAppCounts(udids: udids)) { _installedAppCountsResult }
    }

    package func uninstall(udid: String, bundleID: String, wasBooted: Bool) async throws {
        let error = record(.uninstall(udid: udid, bundleID: bundleID, wasBooted: wasBooted)) { _uninstallError }
        if let error { throw error }
    }

    package func install(udid: String, appPath: String) async throws {
        let error = record(.install(udid: udid, appPath: appPath)) { _installError }
        if let error { throw error }
    }

    package func uninstallQuietly(udid: String, bundleID: String) async {
        record(.uninstallQuietly(udid: udid, bundleID: bundleID)) {}
    }

    package func resetKeychain(udid: String) async throws {
        let error = record(.resetKeychain(udid: udid)) { _resetKeychainError }
        if let error { throw error }
    }

    package func launch(udid: String, bundleID: String, waitForDebugger: Bool, environment: [String: String]) async throws -> Int32? {
        try record(.launch(udid: udid, bundleID: bundleID, waitForDebugger: waitForDebugger, environment: environment)) { try _launchResult.get() }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
