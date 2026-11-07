import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CircleCIRepositoryTests {
    @Test func flakyTestsWithoutASlugRunNoCommand() async throws {
        let recorder = SpyCommandRecorder()
        let repository = CircleCIRepository(client: CircleCIClient(shell: ShellRunner(recorder: recorder)), downloadsFolder: URL(fileURLWithPath: "/tmp/Downloads"))

        let tests = try await repository.flakyTests(project: CIProject(checkoutPath: "/repo", slug: nil))

        #expect(tests.isEmpty)
        #expect(recorder.events.isEmpty)
    }

    @Test func artifactsLandInAFolderNamedAfterTheJob() {
        let repository = CircleCIRepository(client: CircleCIClient(shell: ShellRunner(recorder: SpyCommandRecorder())), downloadsFolder: URL(fileURLWithPath: "/tmp/Downloads"))

        #expect(repository.artifactsFolder(named: "unit-tests 102").path == "/tmp/Downloads/DevHub Artifacts/unit-tests 102")
        #expect(repository.artifactsFolder(named: "a/b:c").path == "/tmp/Downloads/DevHub Artifacts/a-b-c")
        #expect(repository.artifactsFolder(named: "").path == "/tmp/Downloads/DevHub Artifacts/job")
    }
}
