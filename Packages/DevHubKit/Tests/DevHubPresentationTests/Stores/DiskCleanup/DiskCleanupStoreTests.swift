import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct DiskCleanupStoreTests {
    private let harness = StoreHarness()
    private let archives = DiskCleanupItem(id: "archives", kind: .archives, paths: ["/Users/alex/Library/Developer/Xcode/Archives/2026-10-01"], count: 1)
    private let runtime = DiskCleanupItem(id: "runtime:x", kind: .simulatorRuntime, name: "iOS 18.6", size: 9_000, runtimeID: "x")

    private var store: DiskCleanupStore {
        harness.diskCleanup
    }

    @Test func aScanListsTheItemsAndMeasuresOnlyTheUnknownSizes() async {
        harness.spies.diskCleanup.itemsResult = .success([archives, runtime])
        harness.spies.diskCleanup.sizes = ["archives": 4_000]

        await store.scan()

        #expect(store.items == [archives, runtime])
        #expect(store.sizes == ["archives": 4_000])
        #expect(store.measuringIDs.isEmpty)
        #expect(store.isScanning == false)
        #expect(harness.spies.diskCleanup.calls == [.items, .size("archives")])
    }

    @Test func scanIfNeededRunsOnce() async {
        harness.spies.diskCleanup.itemsResult = .success([runtime])

        await store.scanIfNeeded()
        await store.scanIfNeeded()

        #expect(harness.spies.diskCleanup.calls == [.items])
    }

    @Test func aFailedScanShowsTheReason() async {
        harness.spies.diskCleanup.itemsResult = .failure(DiskCleanupError.command("xcrun: error: unable to find utility \"simctl\""))

        await store.scan()

        #expect(store.failure == "xcrun: error: unable to find utility \"simctl\"")
        #expect(store.hasScanned == false)
        #expect(harness.lastActivity?.title == "Cannot read the disk usage")
    }

    @Test func cleaningRemovesTheLineAfterTheOperation() async throws {
        harness.spies.diskCleanup.itemsResult = .success([archives, runtime])
        await store.scan()

        store.clean("runtime:x")

        #expect(store.busyIDs == ["runtime:x"])
        try await waitUntil { store.busyIDs.isEmpty }
        #expect(store.items == [archives])
        #expect(harness.spies.diskCleanup.calls.last == .clean("runtime:x"))
        #expect(harness.operations.latest(at: .disk)?.title == "Delete the iOS 18.6 simulator runtime")
        #expect(harness.operations.latest(at: .disk)?.status == .succeeded)
        #expect(harness.lastActivity?.title == "Delete the iOS 18.6 simulator runtime")
    }

    @Test func aFailedCleanKeepsTheLineAndTheReason() async throws {
        harness.spies.diskCleanup.itemsResult = .success([archives])
        harness.spies.diskCleanup.cleanError = DiskCleanupError.notAllowed("/Users/alex/Documents")
        await store.scan()

        store.clean("archives")

        try await waitUntil { store.busyIDs.isEmpty }
        #expect(store.items == [archives])
        #expect(harness.operations.latest(at: .disk)?.failureMessage == DiskCleanupError.notAllowed("/Users/alex/Documents").localizedDescription)
        #expect(harness.lastActivity?.title == "Delete Archives failed")
    }
}
