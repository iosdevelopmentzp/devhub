import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct SimulatorStatusStoreTests {
    private let harness = StoreHarness()
    private let script = ProjectSample.path + "/scripts/status.sh"

    init() {
        harness.simulators.groups = SimulatorSample.groups
        harness.spies.scripts.events = [.output("Environment: staging"), .exited(0)]
    }

    private var store: SimulatorStatusStore {
        harness.simulatorStatuses
    }

    private var udids: [String?] {
        harness.spies.scripts.calls.map { $0.environment["DEVHUB_SIMULATOR_UDID"] }
    }

    private func load(statusScript: String?) async {
        _ = store
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(simulators: SimulatorsConfig(statusScript: statusScript)), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
    }

    @Test func readsTheStatusOfTheBootedSimulatorOnly() async throws {
        harness.spies.tools.existingFiles = [script]

        await load(statusScript: "scripts/status.sh")
        try await waitUntil { store.statuses.isEmpty == false }

        #expect(store.statuses == [SimulatorSample.booted.id: SimulatorStatus(text: "Environment: staging", isFailure: false)])
        #expect(udids == [SimulatorSample.booted.id])
        #expect(harness.spies.scripts.calls.first?.executable == script)
    }

    @Test func theStatusScriptGetsTheContainersOfTheApp() async throws {
        harness.spies.tools.existingFiles = [script]
        harness.spies.launcher.containersResult = AppContainers(app: "/sim/Bundle/App.app", data: "/sim/Data/App")

        await load(statusScript: "scripts/status.sh")
        try await waitUntil { store.statuses.isEmpty == false }

        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_DATA_CONTAINER"] == "/sim/Data/App")
        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_APP_CONTAINER"] == "/sim/Bundle/App.app")
    }

    @Test func aMissingScriptIsAFailureLine() async throws {
        await load(statusScript: "scripts/status.sh")
        try await waitUntil { store.statuses.isEmpty == false }

        #expect(store.statuses[SimulatorSample.booted.id] == SimulatorStatus(text: "Status script not found: scripts/status.sh", isFailure: true))
        #expect(harness.spies.scripts.calls.isEmpty)
    }

    @Test func withoutAStatusScriptNothingRuns() async {
        harness.spies.tools.existingFiles = [script]

        await load(statusScript: nil)
        store.loadMissing()

        #expect(store.statuses.isEmpty)
        #expect(harness.spies.scripts.calls.isEmpty)
    }

    @Test func aLaunchReadsThatSimulatorAgain() async throws {
        harness.spies.tools.existingFiles = [script]
        await load(statusScript: "scripts/status.sh")
        try await waitUntil { store.statuses.isEmpty == false }
        harness.spies.scripts.events = [.output("Environment: production"), .exited(0)]

        store.loadMissing()
        harness.events.post(.appLaunched(simulatorID: SimulatorSample.booted.id, launch: nil))
        try await waitUntil { store.statuses[SimulatorSample.booted.id]?.text == "Environment: production" }

        #expect(udids == [SimulatorSample.booted.id, SimulatorSample.booted.id])
    }

    @Test func aStateDirectiveIsPostedOnceForTheIdentityPanel() async throws {
        harness.spies.tools.existingFiles = [script]
        harness.spies.scripts.events = [.output(#"@devhub {"state": {"identity": "qa-1"}}"#), .output("Environment: staging"), .exited(0)]

        await load(statusScript: "scripts/status.sh")
        try await waitUntil { store.reports.isEmpty == false }
        store.loadMissing()
        harness.events.post(.appLaunched(simulatorID: SimulatorSample.booted.id, launch: nil))
        try await waitUntil { harness.spies.scripts.calls.count == 2 }
        await harness.settle()

        #expect(store.reports[SimulatorSample.booted.id]?.identity == "qa-1")
        #expect(harness.postCount("appStateReported(sim-booted, qa-1)") == 1)
        #expect(harness.identity.actualIdentity(for: SimulatorSample.booted.id) == "qa-1")
    }
}
