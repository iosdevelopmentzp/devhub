import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct MessagingStoreTests {
    private let harness = StoreHarness()
    private let simulator = SimulatorSample.booted

    private var store: MessagingStore {
        harness.messaging
    }

    // MARK: History

    @Test func historyIsRestoredFromTheStore() {
        let saved = InMemoryKeyValueStore()
        saved.set(["app://one"], forKey: "messaging.urls")
        saved.set(["{}"], forKey: "messaging.payloads")
        let store = StoreHarness(store: saved).messaging

        #expect(store.urlHistory == ["app://one"])
        #expect(store.payloadHistory == ["{}"])
    }

    @Test func openURLRemembersTheTrimmedURLMostRecentFirst() {
        store.url = " app://one "
        store.openURL(on: simulator)
        store.url = "app://two"
        store.openURL(on: simulator)
        store.url = "app://one"
        store.openURL(on: simulator)

        #expect(store.urlHistory == ["app://one", "app://two"])
        #expect(harness.store.strings(forKey: "messaging.urls") == ["app://one", "app://two"])
    }

    @Test func urlHistoryKeepsFifteenEntries() {
        let saved = InMemoryKeyValueStore()
        saved.set((1...15).map { "app://\($0)" }, forKey: "messaging.urls")
        let store = StoreHarness(store: saved).messaging

        store.url = "app://new"
        store.openURL(on: simulator)

        #expect(store.urlHistory.count == 15)
        #expect(store.urlHistory.first == "app://new")
        #expect(store.urlHistory.contains("app://15") == false)
    }

    @Test func payloadHistoryKeepsTenEntries() {
        let saved = InMemoryKeyValueStore()
        saved.set((1...10).map { "{\"aps\":{},\"n\":\($0)}" }, forKey: "messaging.payloads")
        let store = StoreHarness(store: saved).messaging

        store.payload = MessagingStore.silentTemplate
        store.sendPush(to: simulator)

        #expect(store.payloadHistory.count == 10)
        #expect(store.payloadHistory.first == MessagingStore.silentTemplate)
        #expect(saved.strings(forKey: "messaging.payloads")?.first == MessagingStore.silentTemplate)
    }

    @Test func forgetRemovesAURL() {
        store.url = "app://one"
        store.openURL(on: simulator)

        store.forget(url: "app://one")

        #expect(store.urlHistory.isEmpty)
        #expect(harness.store.strings(forKey: "messaging.urls") == [])
    }

    // MARK: Payload

    @Test func payloadErrorNamesTheProblem() {
        store.payload = "not json"
        #expect(store.payloadError == "Invalid JSON")

        store.payload = "[]"
        #expect(store.payloadError == "The payload must be a JSON object")

        store.payload = "{}"
        #expect(store.payloadError == "The payload needs an \"aps\" key")

        store.payload = store.alertTemplate
        #expect(store.payloadError == nil)

        store.payload = MessagingStore.silentTemplate
        #expect(store.payloadError == nil)
    }

    @Test func schemesComeFromTheInstalledApp() async {
        harness.spies.messaging.urlSchemesResult = ["myapp", "myapp-chat"]
        #expect(store.schemes.isEmpty)

        await store.loadSchemes(for: simulator)

        #expect(store.schemes == ["myapp://", "myapp-chat://"])
        #expect(harness.spies.messaging.calls == [.urlSchemes(bundleID: "com.example.app", udid: simulator.id)])
    }

    @Test func theAlertTemplateUsesTheProjectName() {
        #expect(store.payload == MessagingStore.alertTemplate(title: ProjectSample.app.name))
        #expect(store.alertTemplate.contains("\"title\": \"\(ProjectSample.app.name)\""))
    }

    // MARK: Sending

    @Test func openURLCallsTheRepositoryAndLogs() async throws {
        store.url = "app://one"

        store.openURL(on: simulator)

        #expect(store.isBusy(simulator.id))
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.spies.messaging.calls == [.openURL("app://one", udid: simulator.id)])
        #expect(harness.lastActivity?.title == "Opened app://one")
        #expect(harness.lastActivity?.detail == simulator.name)
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func openURLWithAnEmptyURLDoesNothing() {
        store.url = "  "

        store.openURL(on: simulator)

        #expect(store.busyIDs.isEmpty)
        #expect(store.urlHistory.isEmpty)
    }

    @Test func sendPushSendsThePayloadToTheProjectBundle() async throws {
        store.sendPush(to: simulator)

        #expect(store.isBusy(simulator.id))
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.spies.messaging.calls == [.sendPush(store.alertTemplate, bundleID: "com.example.app", udid: simulator.id)])
        #expect(harness.lastActivity?.title == "Sent push to com.example.app")
    }

    @Test func sendPushWithAnInvalidPayloadDoesNothing() {
        store.payload = "{}"

        store.sendPush(to: simulator)

        #expect(store.busyIDs.isEmpty)
        #expect(store.payloadHistory.isEmpty)
    }

    @Test func aFailureLogsAndPostsCommandFailed() async throws {
        let failure = TestError.scripted("boom")
        harness.spies.messaging.openURLError = failure
        store.url = "app://one"

        store.openURL(on: simulator)

        try await waitUntil { store.busyIDs.isEmpty }
        #expect(harness.lastActivity?.title == "Opened app://one failed")
        #expect(harness.lastActivity?.detail == failure.localizedDescription)
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postedLabels == ["commandFailed"])
    }
}
