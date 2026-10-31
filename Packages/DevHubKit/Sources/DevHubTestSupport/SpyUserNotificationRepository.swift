import DevHubDomain
import Foundation

package final class SpyUserNotificationRepository: UserNotificationRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case permission
        case requestPermission
        case post(title: String, body: String?, target: ActivityTarget?)
        case activations
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _permission: NotificationPermission = .allowed
    private var _requestResult: Result<Bool, any Error> = .success(true)
    private var continuation: AsyncStream<ActivityTarget?>.Continuation?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var posted: [Call] {
        calls.filter { if case .post = $0 { true } else { false } }
    }

    package var permissionResult: NotificationPermission {
        get { lock.withLock { _permission } }
        set { lock.withLock { _permission = newValue } }
    }

    package var requestResult: Result<Bool, any Error> {
        get { lock.withLock { _requestResult } }
        set { lock.withLock { _requestResult = newValue } }
    }

    package func permission() async -> NotificationPermission {
        lock.withLock {
            _calls.append(.permission)
            return _permission
        }
    }

    package func requestPermission() async throws -> Bool {
        try lock.withLock {
            _calls.append(.requestPermission)
            return try _requestResult.get()
        }
    }

    package func post(title: String, body: String?, target: ActivityTarget?) async throws {
        lock.withLock { _calls.append(.post(title: title, body: body, target: target)) }
    }

    package func activations() -> AsyncStream<ActivityTarget?> {
        let (stream, continuation) = AsyncStream<ActivityTarget?>.makeStream()
        lock.withLock {
            _calls.append(.activations)
            self.continuation = continuation
        }
        return stream
    }

    package func activate(_ target: ActivityTarget?) {
        lock.withLock { continuation }?.yield(target)
    }
}
