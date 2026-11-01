import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CrashReportsStoreTests {
    private let harness = StoreHarness()
    private let launchedAt = Date(timeIntervalSince1970: 10_000)
    private let simulatorID = "8A1F0C2E-5B6D-4E7F-9A0B-1C2D3E4F5A6B"

    private var store: CrashReportsStore {
        harness.crashes
    }

    @Test func aLaunchStartsWatchingAndFindsTheCrash() async throws {
        harness.spies.crashes.reportsResult = .success([crash("/r/a.ips", bundleID: "com.example.app", after: 30)])
        _ = store

        harness.events.post(.appLaunched(simulatorID: simulatorID, launch: launch()))

        try await waitUntil { store.crashes.count == 1 }
        #expect(store.isWatching)
        #expect(harness.spies.crashes.calls.contains(.changes))
        #expect(harness.spies.crashes.calls.contains(.reports(since: launchedAt.addingTimeInterval(-5))))
        #expect(store.latest?.id == "/r/a.ips")
        #expect(harness.lastActivity?.title == "ExampleApp crashed")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.lastActivity?.kind == .crashes)
        #expect(harness.lastActivity?.target == .build)
    }

    @Test func aLaunchWithoutABundleIDIsIgnored() async {
        _ = store

        harness.events.post(.appLaunched(simulatorID: simulatorID, launch: nil))
        await harness.settle()

        #expect(store.isWatching == false)
        #expect(harness.spies.crashes.calls.isEmpty)
    }

    @Test func otherAppsAndKnownCrashesAreSkipped() async throws {
        harness.spies.crashes.reportsResult = .success([
            crash("/r/a.ips", bundleID: "com.example.app", after: 30),
            crash("/r/b.ips", bundleID: "com.example.notes", after: 30),
        ])
        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)
        try await waitUntil { store.crashes.count == 1 }

        await store.check()

        #expect(store.crashes.map(\.id) == ["/r/a.ips"])
    }

    @Test func aChangeOfTheFolderChecksAgain() async throws {
        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)
        try await waitUntil { harness.spies.crashes.calls.count == 2 }
        harness.spies.crashes.reportsResult = .success([crash("/r/late.ips", bundleID: "com.example.app", after: 90)])

        harness.spies.crashes.emitChange()

        try await waitUntil { store.latest?.id == "/r/late.ips" }
        #expect(harness.spies.crashes.calls.filter { $0 == .changes }.count == 1)
    }

    @Test func newerCrashesComeFirst() async throws {
        harness.spies.crashes.reportsResult = .success([
            crash("/r/second.ips", bundleID: "com.example.app", after: 60),
            crash("/r/first.ips", bundleID: "com.example.app", after: 30),
        ])

        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)

        try await waitUntil { store.crashes.count == 2 }
        #expect(store.crashes.map(\.id) == ["/r/second.ips", "/r/first.ips"])
    }

    @Test func dismissHidesTheCrashAndToggleOpensTheStack() async throws {
        harness.spies.crashes.reportsResult = .success([crash("/r/a.ips", bundleID: "com.example.app", after: 30)])
        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)
        try await waitUntil { store.latest != nil }

        store.toggleReport("/r/a.ips")
        #expect(store.openIDs == ["/r/a.ips"])
        store.dismiss("/r/a.ips")

        #expect(store.latest == nil)
        #expect(store.openIDs.isEmpty)
        #expect(store.crashes.count == 1)
    }

    @Test func aFailedReadIsLogged() async {
        harness.spies.crashes.reportsResult = .failure(TestError.scripted("no access"))
        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)

        await store.check()

        #expect(harness.activityTitles.contains("Cannot read the crash reports"))
    }

    @Test func theFixPromptDescribesTheCrash() async throws {
        harness.spies.crashes.reportsResult = .success([crash("/r/a.ips", bundleID: "com.example.app", after: 30)])
        store.watch(bundleID: "com.example.app", simulatorID: simulatorID, launchedAt: launchedAt)
        try await waitUntil { store.latest != nil }

        let path = await store.writeFixPrompt(id: "/r/a.ips", checkoutName: "~/Projects/example-app")

        let report = try #require(store.crash("/r/a.ips"))
        #expect(path != nil)
        #expect(harness.spies.reviewPrompts.calls.last == .saveNamed(FixPromptBuilder.crash(report, checkoutName: "~/Projects/example-app"), name: "fix-crash-exampleapp"))
        #expect(await store.writeFixPrompt(id: "/r/missing.ips", checkoutName: "x") == nil)
    }

    private func launch() -> LaunchRecord {
        LaunchRecord(bundleID: "com.example.app", profileID: nil, identity: nil, baseURL: nil, date: launchedAt)
    }

    private func crash(_ path: String, bundleID: String, after seconds: TimeInterval) -> CrashReport {
        CrashReport(
            path: path,
            processName: "ExampleApp",
            bundleID: bundleID,
            appVersion: "1.0",
            date: launchedAt.addingTimeInterval(seconds),
            simulatorID: simulatorID,
            exceptionType: "EXC_BAD_ACCESS",
            signal: "SIGSEGV",
            subtype: nil,
            messages: [],
            frames: [CrashReport.Frame(image: "ExampleApp", symbol: "ProfileViewModel.load()", file: "ProfileViewModel.swift", line: 42, isApp: true)]
        )
    }
}
