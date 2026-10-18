import Foundation
import DevHubDomain

struct MockUserNotificationRepository: UserNotificationRepository {

    func permission() async -> NotificationPermission {
        .allowed
    }

    func requestPermission() async throws -> Bool {
        true
    }

    func post(title: String, body: String?) async throws {}
}
