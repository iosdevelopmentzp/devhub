import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct NotifierTests {
    private let harness = StoreHarness()

    private var notifier: Notifier {
        harness.notifier
    }

    @Test func aClosedPanelGetsANotification() async throws {
        notifier.postWhenClosed(title: "Launched App", body: "iPhone 17")

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Launched App", body: "iPhone 17")] }
    }

    @Test func anOpenPanelOrTheSettingStopsIt() async {
        notifier.panelShown(true)
        notifier.postWhenClosed(title: "A", body: nil)
        notifier.panelShown(false)
        harness.settings.values.notifyWhenPanelClosed = false
        notifier.postWhenClosed(title: "B", body: nil)
        await harness.settle()

        #expect(harness.spies.notifications.posted.isEmpty)
    }

    @Test func aRequestChangeFollowsItsOwnSettingAndThePanelRule() async throws {
        harness.settings.values.notifyAboutMyRequests = false
        notifier.postRequestChange(title: "A", body: nil)
        await harness.settle()
        #expect(harness.spies.notifications.posted.isEmpty)

        harness.settings.values.notifyAboutMyRequests = true
        notifier.panelShown(true)
        notifier.postRequestChange(title: "B", body: nil)
        await harness.settle()
        #expect(harness.spies.notifications.posted.isEmpty)

        notifier.panelShown(false)
        notifier.postRequestChange(title: "C", body: "body")
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "C", body: "body")] }
    }

    @Test func withoutPermissionNothingIsPosted() async {
        harness.spies.notifications.permissionResult = .denied

        notifier.post(title: "A", body: nil)
        await harness.settle()

        #expect(harness.spies.notifications.posted.isEmpty)
        #expect(notifier.permission == .denied)
    }

    @Test func aFailureWhileClosedStaysUntilThePanelOpens() {
        notifier.buildFinished(title: "Build failed", detail: "x", failed: true)
        #expect(notifier.hasUnseenFailure)

        notifier.panelShown(true)
        #expect(notifier.hasUnseenFailure == false)

        notifier.buildFinished(title: "Build failed", detail: "x", failed: true)
        #expect(notifier.hasUnseenFailure == false)
    }

    @Test func requestPermissionAsksAndReadsTheResult() async {
        harness.spies.notifications.permissionResult = .allowed

        await notifier.requestPermission()

        #expect(harness.spies.notifications.calls.prefix(2) == [.requestPermission, .permission])
        #expect(notifier.permission == .allowed)
    }
}
