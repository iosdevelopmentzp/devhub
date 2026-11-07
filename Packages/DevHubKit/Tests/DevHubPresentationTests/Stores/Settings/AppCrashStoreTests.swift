import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct AppCrashStoreTests {
    private let harness = StoreHarness()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private var store: AppCrashStore {
        harness.appCrash
    }

    private func crash(at date: Date) -> CrashReport {
        var report = MockData.crashReport
        report.processName = "DevHub"
        report.simulatorID = nil
        report.date = date
        report.messages = ["/Users/alex/Projects/app/HomeView.swift:42: Fatal error"]
        return report
    }

    @Test func theNewestCrashSinceTheFirstLookShowsAndIsLogged() async {
        harness.spies.crashes.ownReportsResult = .success([crash(at: now.addingTimeInterval(-600)), crash(at: now.addingTimeInterval(-7_200))])

        await store.check()

        #expect(store.latest?.date == now.addingTimeInterval(-600))
        #expect(store.notice?.hasPrefix("DevHub crashed ") == true)
        #expect(harness.lastActivity?.title == "DevHub crashed")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.spies.crashes.calls == [.ownReports(processName: "DevHub", bundleID: "com.example.app", since: now.addingTimeInterval(-AppCrashStore.firstLookBack))])
    }

    @Test func dismissSavesTheDateSoTheCrashStaysHidden() async {
        harness.spies.crashes.ownReportsResult = .success([crash(at: now.addingTimeInterval(-600))])
        await store.check()

        store.dismiss()

        #expect(store.latest == nil)
        let reopened = StoreHarness(projects: [ProjectSample.app], store: harness.store)
        reopened.spies.crashes.ownReportsResult = .success([crash(at: now.addingTimeInterval(-600))])
        await reopened.appCrash.check()
        #expect(reopened.appCrash.latest == nil)
        #expect(reopened.spies.crashes.calls == [.ownReports(processName: "DevHub", bundleID: "com.example.app", since: now.addingTimeInterval(-600))])
    }

    @Test func copyRedactsTheReport() async {
        harness.spies.crashes.ownReportsResult = .success([crash(at: now.addingTimeInterval(-600))])
        await store.check()

        await store.copy()

        let text = harness.copied.first ?? ""
        #expect(text.hasPrefix("DevHub crash report\nDevHub: 1.0\n"))
        #expect(text.contains("Message: ~/Projects/app/HomeView.swift:42: Fatal error"))
        #expect(text.contains("/Users/alex") == false)
    }

    @Test func aFailedReadIsLogged() async {
        harness.spies.crashes.ownReportsResult = .failure(PullRequestError.command("no access"))

        await store.check()

        #expect(store.latest == nil)
        #expect(harness.lastActivity?.title == "Cannot read the crash reports of DevHub")
    }
}
