import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIRepositoryTests {
    @Test func flakyTestsWithoutASlugRunNoCommand() async throws {
        let recorder = SpyCommandRecorder()
        let repository = CircleCIRepository(client: CircleCIClient(shell: ShellRunner(recorder: recorder)))

        let tests = try await repository.flakyTests(project: CIProject(checkoutPath: "/repo", slug: nil))

        #expect(tests.isEmpty)
        #expect(recorder.events.isEmpty)
    }
}
