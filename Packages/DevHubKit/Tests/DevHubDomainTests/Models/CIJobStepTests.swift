import Testing
@testable import DevHubDomain

@Suite struct CIJobStepTests {
    @Test func aStepFailsByItsStateOrItsExitCode() {
        #expect(CIJobStep(index: 0, name: "Run", status: .failed, duration: nil, exitCode: nil).isFailed)
        #expect(CIJobStep(index: 0, name: "Run", status: .success, duration: nil, exitCode: 65).isFailed)
        #expect(CIJobStep(index: 0, name: "Run", status: .success, duration: 1, exitCode: 0).isFailed == false)
        #expect(CIJobStep(index: 0, name: "Run", status: .running, duration: nil, exitCode: nil).isFailed == false)
    }
}
