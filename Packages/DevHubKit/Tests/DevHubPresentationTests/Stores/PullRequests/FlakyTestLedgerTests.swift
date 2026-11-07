import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct FlakyTestLedgerTests {
    private let harness = StoreHarness()
    private let flake = CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 1, source: .devhub)

    @Test func recordedFlakesAreSavedPerProject() {
        harness.flakyTests.record([flake], at: Date(timeIntervalSince1970: 1_000))

        let reopened = StoreHarness(projects: [ProjectSample.app], store: harness.store)

        #expect(reopened.flakyTests.tests == [flake])
        #expect(harness.store.data(forKey: "gitlab.flakyTests.\(harness.session.selectedProjectID)") != nil)
    }

    @Test func forgetRemovesEverything() {
        harness.flakyTests.record([flake], at: .now)

        harness.flakyTests.forget()

        #expect(harness.flakyTests.records.isEmpty)
        #expect(harness.store.data(forKey: "gitlab.flakyTests.\(harness.session.selectedProjectID)") == nil)
    }

    @Test func noFlakesWriteNothing() {
        harness.flakyTests.record([], at: .now)

        #expect(harness.store.data(forKey: "gitlab.flakyTests.\(harness.session.selectedProjectID)") == nil)
        #expect(FlakyLedgerText.title(count: 0) == "No flaky tests found by DevHub yet")
        #expect(FlakyLedgerText.title(count: 2) == "2 flaky tests found by DevHub")
    }
}
