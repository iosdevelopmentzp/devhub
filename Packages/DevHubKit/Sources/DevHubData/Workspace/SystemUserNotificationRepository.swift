import Foundation
import DevHubDomain
import UserNotifications

final class SystemUserNotificationRepository: UserNotificationRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var delegate: NotificationCenterDelegate?
    private var stream: AsyncStream<ActivityTarget?>?

    func permission() async -> NotificationPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notAsked
        case .denied: return .denied
        default: return .allowed
        }
    }

    func requestPermission() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func post(title: String, body: String?, target: ActivityTarget?) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body {
            content.body = LogRedactor.redact(body)
        }
        content.userInfo = NotificationTargetCodec.userInfo(for: target)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }

    func activations() -> AsyncStream<ActivityTarget?> {
        lock.withLock {
            if let stream {
                return stream
            }
            let (stream, continuation) = AsyncStream<ActivityTarget?>.makeStream()
            let delegate = NotificationCenterDelegate(continuation: continuation)
            UNUserNotificationCenter.current().delegate = delegate
            self.delegate = delegate
            self.stream = stream
            return stream
        }
    }
}
