import Testing
@testable import DevHubDomain

@Suite struct CIFailureKindTests {
    @Test func theReasonNamesTheJobAndTheCount() {
        #expect(CIFailureKind.allFlaky(testCount: 1).reason == "the failed test is flaky")
        #expect(CIFailureKind.allFlaky(testCount: 3).reason == "all 3 failed tests are flaky")
        #expect(CIFailureKind.realTests(job: "unit-tests", count: 1).reason == "unit-tests failed on a test that is not flaky")
        #expect(CIFailureKind.realTests(job: "unit-tests", count: 2).reason == "unit-tests failed on 2 tests that are not flaky")
        #expect(CIFailureKind.noTests(job: "build").reason == "build failed without test results")
    }
}
