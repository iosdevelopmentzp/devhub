import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockXcodeAttacherTests {
    @Test func isTrustedAndAttaches() async throws {
        let attacher = MockXcodeAttacher()

        #expect(attacher.isTrusted)
        attacher.requestTrust()
        try await attacher.attach(pid: 4242, destination: .simulator("sim"), projectPath: "~/App", container: nil)
    }
}
