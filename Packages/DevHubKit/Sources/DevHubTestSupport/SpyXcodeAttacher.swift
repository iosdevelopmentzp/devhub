import DevHubDomain
import Foundation

package final class SpyXcodeAttacher: XcodeAttaching, @unchecked Sendable {
    package enum Call: Hashable {
        case requestTrust
        case attach(pid: Int32, simulatorUDID: String, projectPath: String, container: String?)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _isTrusted: Bool = true
    private var _attachError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var isTrusted: Bool {
        get { lock.withLock { _isTrusted } }
        set { lock.withLock { _isTrusted = newValue } }
    }

    package var attachError: (any Error)? {
        get { lock.withLock { _attachError } }
        set { lock.withLock { _attachError = newValue } }
    }

    package func requestTrust() {
        record(.requestTrust) {}
    }

    package func attach(pid: Int32, simulatorUDID: String, projectPath: String, container: String?) async throws {
        let error = record(.attach(pid: pid, simulatorUDID: simulatorUDID, projectPath: projectPath, container: container)) { _attachError }
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
