import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct LogsStoreTests {
    private let harness = StoreHarness()
    private let udid = SimulatorSample.booted.id

    init() {
        harness.simulators.groups = SimulatorSample.groups
    }

    private var store: LogsStore {
        harness.logs
    }

    private var stream: LogStream? {
        store.streams.first { $0.id == udid }
    }

    private func startStreaming() async throws {
        store.stream(on: udid)
        store.setProcess("App", for: udid)
        try await waitUntil { harness.spies.logs.calls.contains { if case .stream = $0 { true } else { false } } }
    }

    // MARK: Persistence

    @Test func streamsAndSelectionAreRestored() {
        let saved = InMemoryKeyValueStore()
        saved.encode([LogStreamSettings(udid: udid, name: "iPhone 17", process: "App", subsystem: "sub", level: AppLogLine.Level.error.rawValue)], forKey: "logs.streams")
        saved.set(udid, forKey: "logs.selected")

        let store = StoreHarness(store: saved).logs

        #expect(store.streams.map(\.settings) == [LogStreamSettings(udid: udid, name: "iPhone 17", process: "App", subsystem: "sub", level: AppLogLine.Level.error.rawValue)])
        #expect(store.selected?.id == udid)
        #expect(store.selected?.minimumLevel == .error)
    }

    @Test func filterChangesAreWritten() {
        store.prepare(defaultUDID: udid)
        store.setProcess("Other", for: udid)
        store.setSubsystem("com.example", for: udid)
        store.setLevel(.notice, for: udid)

        let saved = harness.store.decode([LogStreamSettings].self, forKey: "logs.streams")
        #expect(saved == [LogStreamSettings(udid: udid, name: SimulatorSample.booted.name, process: "Other", subsystem: "com.example", level: AppLogLine.Level.notice.rawValue)])
        #expect(harness.store.string(forKey: "logs.selected") == udid)
    }

    // MARK: Prepare

    @Test func prepareAddsTheDefaultSimulatorWithTheConfigFilter() async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(logs: LogsConfig(process: "Proc", subsystem: "com.example.app")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()

        store.prepare(defaultUDID: udid)

        #expect(store.streams.map(\.id) == [udid])
        #expect(stream?.process == "Proc")
        #expect(stream?.subsystem == "com.example.app")
        #expect(stream?.isRunning == false)
        #expect(harness.spies.logs.calls.isEmpty)
    }

    @Test func prepareKeepsExistingStreams() {
        store.prepare(defaultUDID: udid)
        store.prepare(defaultUDID: SimulatorSample.shutdown.id)

        #expect(store.streams.map(\.id) == [udid])
    }

    @Test func availableSimulatorsAreBootedOnesWithoutAStream() {
        #expect(store.availableSimulators.map(\.id) == [udid])

        store.prepare(defaultUDID: udid)

        #expect(store.availableSimulators.isEmpty)
    }

    // MARK: Streaming

    @Test func streamOnFindsTheProcessAndStarts() async throws {
        harness.spies.logs.executableNameResult = "AppProcess"

        store.stream(on: udid)

        #expect(store.selected?.id == udid)
        try await waitUntil { harness.spies.logs.calls.contains(.stream(udid: udid, filter: AppLogFilter(process: "AppProcess", subsystem: ""))) }
        #expect(harness.spies.logs.calls.first == .executableName(udid: udid, bundleID: "com.example.app"))
        #expect(stream?.isRunning == true)
        #expect(stream?.process == "AppProcess")
    }

    @Test func twoSimulatorsStreamAtOnce() async throws {
        let second = Simulator(id: "sim-second", name: "iPad Pro", kind: .pad, state: .booted, isFavorite: false)
        harness.simulators.groups = [SimulatorGroup(runtime: "iOS 26.0", simulators: [SimulatorSample.booted, second])]
        harness.spies.logs.executableNameResult = "App"

        store.stream(on: udid)
        store.stream(on: second.id)
        try await waitUntil { harness.spies.logs.calls.filter { if case .stream = $0 { true } else { false } }.count == 2 }
        harness.spies.logs.emit(AppLogLineSample.debug, on: udid)
        harness.spies.logs.emit(AppLogLineSample.error, on: second.id)

        try await waitUntil { store.streams.allSatisfy { $0.lines.count == 1 } }
        #expect(store.streams.map(\.lines) == [[AppLogLineSample.debug], [AppLogLineSample.error]])
        #expect(store.selected?.id == second.id)
    }

    @Test func theLevelFiltersVisibleLines() async throws {
        try await startStreaming()

        harness.spies.logs.emit(AppLogLineSample.debug, on: udid)
        harness.spies.logs.emit(AppLogLineSample.error, on: udid)
        try await waitUntil { stream?.lines.count == 2 }
        store.setLevel(.error, for: udid)

        #expect(stream?.visibleLines == [AppLogLineSample.error])
    }

    @Test func pauseKeepsLinesPendingUntilResumed() async throws {
        try await startStreaming()
        store.setPaused(true, for: udid)

        harness.spies.logs.emit(AppLogLineSample.debug, on: udid)
        try await waitUntil { stream?.pending.count == 1 }
        #expect(stream?.lines.isEmpty == true)

        store.setPaused(false, for: udid)

        #expect(stream?.lines == [AppLogLineSample.debug])
        #expect(stream?.pending.isEmpty == true)
    }

    @Test func stopEndsTheStream() async throws {
        try await startStreaming()

        store.stop(udid)

        #expect(stream?.isRunning == false)
    }

    @Test func aFailedStreamShowsTheError() async throws {
        try await startStreaming()

        harness.spies.logs.finish(udid, throwing: AppLogError.streamStopped(1))

        try await waitUntil { stream?.error != nil }
        #expect(stream?.error == AppLogError.streamStopped(1).localizedDescription)
        #expect(stream?.isRunning == false)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func withoutAnExecutableNameTheSchemeIsTheProcess() async throws {
        store.stream(on: udid)

        try await waitUntil { harness.spies.logs.calls.contains(.stream(udid: udid, filter: AppLogFilter(process: "App", subsystem: ""))) }
        #expect(stream?.process == "App")
    }

    @Test func removeStopsAndSelectsTheNextStream() async throws {
        try await startStreaming()

        store.remove(udid)

        #expect(store.streams.isEmpty)
        #expect(store.selected == nil)
        #expect(harness.store.decode([LogStreamSettings].self, forKey: "logs.streams") == [])
    }

    @Test func clearRemovesEverything() async throws {
        try await startStreaming()
        harness.spies.logs.emit(AppLogLineSample.debug, on: udid)
        try await waitUntil { stream?.lines.isEmpty == false }

        store.clear(udid)

        #expect(stream?.lines.isEmpty == true)
        #expect(stream?.pending.isEmpty == true)
        #expect(stream?.dropped == 0)
    }

    @Test func availableSimulatorsSkipPhysicalDevices() {
        harness.simulators.groups = [SimulatorGroup(runtime: SimulatorGroup.devicesTitle, simulators: [SimulatorSample.device])] + SimulatorSample.groups

        #expect(store.availableSimulators.map(\.id) == [udid])

        store.stream(on: SimulatorSample.device.id)

        #expect(store.streams.isEmpty)
    }
}
