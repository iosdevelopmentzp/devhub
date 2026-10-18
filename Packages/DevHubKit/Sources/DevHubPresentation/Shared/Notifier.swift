import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class Notifier {
    private(set) var permission: NotificationPermission = .notAsked
    private(set) var isPanelShown = false
    private(set) var hasUnseenFailure = false

    @ObservationIgnored private let repository: any UserNotificationRepository
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let activity: ActivityLog

    init(repository: any UserNotificationRepository, settings: SettingsStore, activity: ActivityLog) {
        self.repository = repository
        self.settings = settings
        self.activity = activity
    }

    func panelShown(_ shown: Bool) {
        guard shown != isPanelShown else { return }
        isPanelShown = shown
        if shown {
            hasUnseenFailure = false
        }
    }

    func refreshPermission() async {
        let current = await repository.permission()
        guard current != permission else { return }
        permission = current
    }

    func requestPermission() async {
        do {
            _ = try await repository.requestPermission()
        } catch {
            activity.log("Could not ask for notification permission", detail: error.localizedDescription, outcome: .failure)
        }
        await refreshPermission()
    }

    func buildFinished(title: String, detail: String, failed: Bool) {
        if failed, isPanelShown == false {
            hasUnseenFailure = true
        }
        postWhenClosed(title: title, body: detail)
    }

    func postWhenClosed(title: String, body: String?) {
        guard isPanelShown == false, settings.values.notifyWhenPanelClosed else { return }
        post(title: title, body: body)
    }

    func post(title: String, body: String?) {
        Task { [weak self] in
            guard let self else { return }
            await deliver(title: title, body: body)
        }
    }

    private func deliver(title: String, body: String?) async {
        await refreshPermission()
        guard permission == .allowed else { return }
        do {
            try await repository.post(title: title, body: body)
        } catch {
            activity.log("Could not show a notification", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
