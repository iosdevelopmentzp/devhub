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

    func activations() -> AsyncStream<ActivityTarget?> {
        repository.activations()
    }

    func buildFinished(title: String, detail: String, symbol: NotificationSymbol) {
        if symbol == .failure, isPanelShown == false {
            hasUnseenFailure = true
        }
        notify(.build, symbol: symbol, title: title, body: detail, target: .build)
    }

    func notify(_ kind: NotificationKind, symbol: NotificationSymbol?, title: String, body: String?, target: ActivityTarget?) {
        guard settings.values.notifies(kind) else { return }
        if kind.showsWhilePanelIsOpen == false {
            guard isPanelShown == false, settings.values.notifyWhenPanelClosed else { return }
        }
        let shown = NotificationSymbol.title(title, symbol: symbol, showsEmoji: settings.values.notificationEmoji)
        Task { [weak self] in
            guard let self else { return }
            await deliver(title: shown, body: body, target: target)
        }
    }

    private func deliver(title: String, body: String?, target: ActivityTarget?) async {
        await refreshPermission()
        guard permission == .allowed else { return }
        do {
            try await repository.post(title: title, body: body, target: target)
        } catch {
            activity.log("Could not show a notification", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
