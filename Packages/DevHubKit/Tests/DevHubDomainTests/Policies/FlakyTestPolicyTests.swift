import Testing
@testable import DevHubDomain

@Suite struct FlakyTestPolicyTests {
    private let retry = CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: nil, message: nil)
    private let badge = CITestResult(className: "BadgeTests", name: "testCount", result: "failure", runTime: nil, message: nil)
    private let flaky = [
        CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit", workflowName: "build", timesFlaked: 3),
        CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "ui", workflowName: "build", timesFlaked: 7),
        CIFlakyTest(className: "OtherTests", name: "testCount", jobName: "unit", workflowName: "build", timesFlaked: 1),
    ]

    @Test func aTestMatchesByClassAndNameWithTheHighestCount() {
        #expect(FlakyTestPolicy.timesFlaked(retry, in: flaky) == 7)
        #expect(FlakyTestPolicy.timesFlaked(badge, in: flaky) == nil)
    }

    @Test func isFlakyAndTheCountFollowTheMatches() {
        #expect(FlakyTestPolicy.isFlaky(retry, in: flaky))
        #expect(FlakyTestPolicy.isFlaky(badge, in: flaky) == false)
        #expect(FlakyTestPolicy.flakyCount(of: [retry, badge], in: flaky) == 1)
        #expect(FlakyTestPolicy.flakyCount(of: [retry, badge], in: []) == 0)
    }
}
