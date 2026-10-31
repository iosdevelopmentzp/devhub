import Foundation
import DevHubDomain
import UserNotifications

final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let continuation: AsyncStream<ActivityTarget?>.Continuation

    init(continuation: AsyncStream<ActivityTarget?>.Continuation) {
        self.continuation = continuation
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        continuation.yield(NotificationTargetCodec.target(from: response.notification.request.content.userInfo))
    }
}
