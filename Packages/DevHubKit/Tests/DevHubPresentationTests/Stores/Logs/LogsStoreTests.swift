import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct LogsStoreTests {
    private let harness = StoreHarness()
    private let udid = SimulatorSample.booted.id

    private var store: LogsStore {
        harness.logs
    }

    private func startStreaming() async throws {
        store.selectedUDID = udid
        store.process = "App"
        store.start()
        try await waitUntil { harness.spies.logs.calls.contains(.stream(udid: udid, process: "App")) }
    }

    // MARK: Persistence

    @Test func simulatorAndLevelAreRestored() {
        let saved = InMemoryKeyValueStore()
        saved.set(udid, forKey: "logs.simulator")
        saved.set(AppLogLine.Level.error.rawValue, forKey: "logs.level")

        let store = StoreHarness(store: saved).logs

        #expect(store.selectedUDID == udid)
        #expect(store.minimumLevel == .error)
    }

    @Test func simulatorAndLevelAreWritten() {
        store.selectedUDID = udid
        store.minimumLevel = .notice

        #expect(harness.store.string(forKey: "logs.simulator") == udid)
        #expect(harness.store.integer(forKey: "logs.level") == AppLogLine.Level.notice.rawValue)
    }

    // MARK: Prepare

    @Test func prepareReplacesAnUnknownSelectionAndFindsTheProcess() async {
        harness.spies.logs.executableNameResult = "AppProcess"
        store.selectedUDID = "gone"

        await store.prepare(defaultUDID: udid, knownUDIDs: [udid])

        #expect(store.selectedUDID == udid)
        #expect(store.process == "AppProcess")
        #expect(harness.spies.logs.calls == [.executableName(udid: udid, bundleID: "com.example.app")])
    }

    @Test func prepareKeepsTheSelectionWhenNoSimulatorsAreKnown() async {
        store.selectedUDID = "kept"

        await store.prepare(defaultUDID: udid, knownUDIDs: [])

        #expect(store.selectedUDID == "kept")
        #expect(store.process == "App")
    }

    @Test func prepareKeepsATypedProcess() async {
        store.process = "Typed"

        await store.prepare(defaultUDID: udid, knownUDIDs: [udid])

        #expect(store.selectedUDID == udid)
        #expect(store.process == "Typed")
        #expect(harness.spies.logs.calls.isEmpty)
    }

    @Test func prepareWithoutASimulatorLeavesTheProcessEmpty() async {
        await store.prepare(defaultUDID: nil, knownUDIDs: [])

        #expect(store.selectedUDID == nil)
        #expect(store.process.isEmpty)
    }

    // MARK: Streaming

    @Test func streamOnFindsTheProcessAndStarts() async throws {
        store.stream(on: udid)

        #expect(store.selectedUDID == udid)
        try await waitUntil { harness.spies.logs.calls.contains(.stream(udid: udid, process: "App")) }
        #expect(store.isStreaming)
        #expect(store.streamingUDID == udid)
        #expect(store.streamingProcess == "App")
    }

    @Test func emittedLinesBecomeVisible() async throws {
        try await startStreaming()

        harness.spies.logs.emit(AppLogLineSample.debug)
        harness.spies.logs.emit(AppLogLineSample.error)

        try await waitUntil { store.lines.count == 2 }
        #expect(store.visibleLines == [AppLogLineSample.debug, AppLogLineSample.error])

        store.minimumLevel = .error

        #expect(store.visibleLines == [AppLogLineSample.error])
    }

    @Test func pauseKeepsLinesPendingUntilResumed() async throws {
        try await startStreaming()
        store.isPaused = true

        harness.spies.logs.emit(AppLogLineSample.debug)

        try await waitUntil { store.pendingCount == 1 }
        #expect(store.lines.isEmpty)

        store.isPaused = false

        #expect(store.lines == [AppLogLineSample.debug])
        #expect(store.pendingCount == 0)
    }

    @Test func stopEndsTheStream() async throws {
        try await startStreaming()

        store.stop()

        #expect(store.isStreaming == false)
        #expect(store.streamingProcess == nil)
    }

    @Test func aFailedStreamShowsTheError() async throws {
        try await startStreaming()

        harness.spies.logs.finish(throwing: AppLogError.streamStopped(1))

        try await waitUntil { store.error != nil }
        #expect(store.error == AppLogError.streamStopped(1).localizedDescription)
        #expect(store.isStreaming == false)
    }

    @Test func startWithoutASimulatorDoesNothing() {
        store.process = "App"

        store.start()

        #expect(store.isStreaming == false)
    }

    @Test func clearRemovesEverything() async throws {
        try await startStreaming()
        harness.spies.logs.emit(AppLogLineSample.debug)
        try await waitUntil { store.lines.isEmpty == false }

        store.clear()

        #expect(store.lines.isEmpty)
        #expect(store.pendingCount == 0)
        #expect(store.droppedLines == 0)
    }
}
