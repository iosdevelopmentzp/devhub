import Testing
@testable import DevHubDomain

@Suite struct CITestResultTests {
    @Test(arguments: [("failure", true), ("failed", true), ("error", true), ("success", false), ("skipped", false), ("", false)])
    func isFailureFollowsTheResultWord(result: String, expected: Bool) {
        #expect(CITestResult(className: "A", name: "b", result: result, runTime: nil, message: nil).isFailure == expected)
    }
}
