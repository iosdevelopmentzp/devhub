import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubPresentation

@Suite struct NotifierTests {
    private let harness = StoreHarness()

    private var notifier: Notifier {
        harness.notifier
    }

    @Test func aClosedPanelGetsANotificationWithItsTarget() async throws {
        notifier.notify(.tests, title: "Tests passed", body: "12 passed", target: .worktree(path: "/repo/.worktrees/a"))

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Tests passed", body: "12 passed", target: .worktree(path: "/repo/.worktrees/a"))] }
    }

    @Test func anOpenPanelOrTheMainSwitchStopsIt() async {
        notifier.panelShown(true)
        notifier.notify(.build, title: "A", body: nil, target: .build)
        notifier.panelShown(false)
        harness.settings.values.notifyWhenPanelClosed = false
        notifier.notify(.build, title: "B", body: nil, target: .build)
        await harness.settle()

        #expect(harness.spies.notifications.posted.isEmpty)
    }

    @Test func aMutedKindIsSilentAndTheOthersAreNot() async throws {
        harness.settings.values.setNotifies(.requestComments, false)

        notifier.notify(.requestComments, title: "A", body: nil, target: .pullRequest(iid: 1))
        notifier.notify(.requestReviews, title: "B", body: nil, target: .pullRequest(iid: 1))

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "B", body: nil, target: .pullRequest(iid: 1))] }
    }

    @Test func aScriptNotificationIgnoresThePanelAndTheMainSwitch() async throws {
        notifier.panelShown(true)
        harness.settings.values.notifyWhenPanelClosed = false

        notifier.notify(.scripts, title: "Done", body: "Resources ready", target: nil)

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Done", body: "Resources ready", target: nil)] }
    }

    @Test func aMutedScriptKindIsSilent() async {
        harness.settings.values.setNotifies(.scripts, false)

        notifier.notify(.scripts, title: "Done", body: nil, target: nil)
        await harness.settle()

        #expect(harness.spies.notifications.posted.isEmpty)
    }

    @Test func withoutPermissionNothingIsPosted() async {
        harness.spies.notifications.permissionResult = .denied

        notifier.notify(.scripts, title: "A", body: nil, target: nil)
        await harness.settle()

        #expect(harness.spies.notifications.posted.isEmpty)
        #expect(notifier.permission == .denied)
    }

    @Test func aFailureWhileClosedStaysUntilThePanelOpens() async throws {
        notifier.buildFinished(title: "Build failed", detail: "x", failed: true)
        #expect(notifier.hasUnseenFailure)
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Build failed", body: "x", target: .build)] }

        notifier.panelShown(true)
        #expect(notifier.hasUnseenFailure == false)

        notifier.buildFinished(title: "Build failed", detail: "x", failed: true)
        #expect(notifier.hasUnseenFailure == false)
    }

    @Test func activationsComeFromTheRepository() async throws {
        let stream = notifier.activations()
        harness.spies.notifications.activate(.pullRequest(iid: 4))

        var iterator = stream.makeAsyncIterator()
        let first = await iterator.next()

        #expect(first == .pullRequest(iid: 4))
        #expect(harness.spies.notifications.calls.first == .activations)
    }

    @Test func requestPermissionAsksAndReadsTheResult() async {
        harness.spies.notifications.permissionResult = .allowed

        await notifier.requestPermission()

        #expect(harness.spies.notifications.calls.prefix(2) == [.requestPermission, .permission])
        #expect(notifier.permission == .allowed)
    }
}
