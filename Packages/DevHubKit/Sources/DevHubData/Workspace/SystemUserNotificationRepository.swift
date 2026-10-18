import Foundation
import DevHubDomain
import UserNotifications

struct SystemUserNotificationRepository: UserNotificationRepository {

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

    func post(title: String, body: String?) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        if let body {
            content.body = LogRedactor.redact(body)
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try await UNUserNotificationCenter.current().add(request)
    }
}
