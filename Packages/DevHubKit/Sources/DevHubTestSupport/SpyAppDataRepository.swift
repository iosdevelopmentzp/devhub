import DevHubDomain
import Foundation

package final class SpyAppDataRepository: AppDataRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case read(udid: String, bundleID: String)
        case write(AppDefaultValue, key: String, plistPath: String, udid: String)
        case delete(key: String, plistPath: String, udid: String)
        case reset(bundleID: String, udid: String, includingGroups: Bool)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _readResult: Result<AppData, any Error> = .failure(AppDataError.notInstalled("com.example.app"))
    private var _actionError: (any Error)?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var readResult: Result<AppData, any Error> {
        get { lock.withLock { _readResult } }
        set { lock.withLock { _readResult = newValue } }
    }

    package var actionError: (any Error)? {
        get { lock.withLock { _actionError } }
        set { lock.withLock { _actionError = newValue } }
    }

    package func read(udid: String, bundleID: String) async throws -> AppData {
        try lock.withLock {
            _calls.append(.read(udid: udid, bundleID: bundleID))
            return try _readResult.get()
        }
    }

    package func write(_ value: AppDefaultValue, key: String, plistPath: String, udid: String) async throws {
        try record(.write(value, key: key, plistPath: plistPath, udid: udid))
    }

    package func delete(key: String, plistPath: String, udid: String) async throws {
        try record(.delete(key: key, plistPath: plistPath, udid: udid))
    }

    package func reset(_ data: AppData, udid: String, includingGroups: Bool) async throws {
        try record(.reset(bundleID: data.bundleID, udid: udid, includingGroups: includingGroups))
    }

    private func record(_ call: Call) throws {
        try lock.withLock {
            _calls.append(call)
            if let _actionError { throw _actionError }
        }
    }
}
