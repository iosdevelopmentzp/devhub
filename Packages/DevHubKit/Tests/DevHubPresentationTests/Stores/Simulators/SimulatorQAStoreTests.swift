import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct SimulatorQAStoreTests {
    private let harness = StoreHarness()

    private var store: SimulatorQAStore {
        harness.simulatorQA
    }

    @Test func aSettingGoesToTheSimulatorAndIsLogged() async throws {
        store.apply(.appearance(.dark), to: SimulatorFixture.iPhone)
        #expect(store.isBusy(SimulatorFixture.iPhone.id))
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(harness.spies.simulatorSettings.calls == [.apply(.appearance(.dark), udid: SimulatorFixture.iPhone.id)])
        #expect(harness.lastActivity?.title == "Dark appearance on iPhone 16 Pro")
        #expect(store.needsReboot.isEmpty)
    }

    @Test func aLanguageNeedsARebootUntilTheSimulatorShutsDown() async throws {
        store.apply(.language(code: "de", locale: "de_DE"), to: SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(store.needsReboot == [SimulatorFixture.iPhone.id])

        store.rebooted(SimulatorFixture.iPhone.id)
        #expect(store.needsReboot.isEmpty)
    }

    @Test func aScreenshotGoesToTheFolderAndIsRemembered() async throws {
        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        let path = "/tmp/DevHubTests/Shots/iPhone 16 Pro 2027-01-15 080000.png"
        #expect(harness.spies.simulatorSettings.calls == [.screenshot(udid: SimulatorFixture.iPhone.id, path: path)])
        #expect(store.screenshots[SimulatorFixture.iPhone.id] == path)
    }

    @Test func aFailureIsLoggedAndNothingIsRemembered() async throws {
        harness.spies.simulatorSettings.error = SimulatorError.command("not booted")

        store.screenshot(SimulatorFixture.iPhone)
        try await waitUntil { store.busyIDs.isEmpty }

        #expect(harness.lastActivity?.outcome == .failure)
        #expect(store.screenshots.isEmpty)
    }
}
