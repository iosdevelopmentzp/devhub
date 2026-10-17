import DevHubDomain
import Foundation

package final class SpySimulatorMessagingRepository: SimulatorMessagingRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case openURL(String, udid: String)
        case sendPush(String, bundleID: String, udid: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _openURLError: (any Error)? = nil
    private var _sendPushError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var openURLError: (any Error)? {
        get { lock.withLock { _openURLError } }
        set { lock.withLock { _openURLError = newValue } }
    }

    package var sendPushError: (any Error)? {
        get { lock.withLock { _sendPushError } }
        set { lock.withLock { _sendPushError = newValue } }
    }

    package func openURL(_ url: String, udid: String) async throws {
        let error = record(.openURL(url, udid: udid)) { _openURLError }
        if let error { throw error }
    }

    package func sendPush(_ payload: String, bundleID: String, udid: String) async throws {
        let error = record(.sendPush(payload, bundleID: bundleID, udid: udid)) { _sendPushError }
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
