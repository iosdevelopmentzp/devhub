import Foundation

package protocol UserNotificationRepository: Sendable {
    func permission() async -> NotificationPermission
    func requestPermission() async throws -> Bool
    func post(title: String, body: String?) async throws
}
