import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct AppDataStoreTests {
    private let harness = StoreHarness()

    private var store: AppDataStore {
        harness.appData
    }

    @Test func loadReadsTheDataOfTheApp() async {
        harness.spies.appData.readResult = .success(AppDataSample.data)

        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        #expect(harness.spies.appData.calls == [.read(udid: "U1", bundleID: "com.example.app")])
        #expect(store.data["U1"] == AppDataSample.data)
        #expect(store.errors["U1"] == nil)
        #expect(store.isBusy("U1") == false)
    }

    @Test func loadWithoutABundleIDDoesNothing() async {
        await store.load(simulatorID: "U1", bundleID: "")

        #expect(harness.spies.appData.calls.isEmpty)
    }

    @Test func aFailedLoadShowsTheErrorAndLogsIt() async {
        harness.spies.appData.readResult = .failure(AppDataError.notInstalled("com.example.app"))

        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        #expect(store.data["U1"] == nil)
        #expect(store.errors["U1"]?.contains("not installed") == true)
        #expect(harness.lastActivity?.title == "Cannot read app data of com.example.app")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func forgetDropsTheData() async {
        harness.spies.appData.readResult = .success(AppDataSample.data)
        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        store.forget(simulatorID: "U1")

        #expect(store.data["U1"] == nil)
    }

    @Test func writeRunsAsAnOperationThenReadsAgain() async throws {
        harness.spies.appData.readResult = .success(AppDataSample.data)
        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        store.write(.bool(false), key: "onboardingDone", in: AppDataSample.appSuite, simulatorID: "U1")

        try await waitUntil { harness.spies.appData.calls.count == 3 && store.isBusy("U1") == false }
        #expect(harness.spies.appData.calls == [
            .read(udid: "U1", bundleID: "com.example.app"),
            .write(.bool(false), key: "onboardingDone", plistPath: AppDataSample.appSuite.plistPath, udid: "U1"),
            .read(udid: "U1", bundleID: "com.example.app"),
        ])
        #expect(harness.operations.latest(at: .simulator("U1"))?.title == "Set onboardingDone in com.example.app")
        #expect(harness.operations.latest(at: .simulator("U1"))?.status == .succeeded)
        #expect(harness.activityTitles.contains("Set onboardingDone in com.example.app"))
    }

    @Test func deleteRemovesTheKeyOfTheSuite() async throws {
        harness.spies.appData.readResult = .success(AppDataSample.data)
        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        store.delete(key: "widgetTheme", in: AppDataSample.groupSuite, simulatorID: "U1")

        try await waitUntil { harness.spies.appData.calls.count == 3 }
        #expect(harness.spies.appData.calls[1] == .delete(key: "widgetTheme", plistPath: AppDataSample.groupSuite.plistPath, udid: "U1"))
    }

    @Test func resetPassesTheGroupChoice() async throws {
        harness.spies.appData.readResult = .success(AppDataSample.data)
        await store.load(simulatorID: "U1", bundleID: "com.example.app")

        store.reset(simulatorID: "U1", includingGroups: true)

        try await waitUntil { harness.spies.appData.calls.count == 3 }
        #expect(harness.spies.appData.calls[1] == .reset(bundleID: "com.example.app", udid: "U1", includingGroups: true))
        #expect(harness.operations.latest(at: .simulator("U1"))?.title == "Reset app data of com.example.app")
    }

    @Test func aFailedActionFailsTheOperationAndLogsIt() async throws {
        harness.spies.appData.readResult = .success(AppDataSample.data)
        await store.load(simulatorID: "U1", bundleID: "com.example.app")
        harness.spies.appData.actionError = AppDataError.command("Unable to lookup in current state: Shutdown")

        store.reset(simulatorID: "U1", includingGroups: false)

        try await waitUntil { harness.spies.appData.calls.count == 3 }
        #expect(harness.operations.latest(at: .simulator("U1"))?.failureMessage == "Unable to lookup in current state: Shutdown")
        #expect(harness.activityTitles.contains("Reset app data of com.example.app failed"))
    }

    @Test func actionsWaitForTheData() async {
        store.reset(simulatorID: "U1", includingGroups: false)
        await harness.settle()

        #expect(harness.spies.appData.calls.isEmpty)
    }
}
