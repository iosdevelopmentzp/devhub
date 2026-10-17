import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct PortsMockTests {
    @Test func buildsAndAnswersFromMockData() async throws {
        let ports = Ports.mock()

        #expect(try await ports.simulators.list() == MockData.simulatorGroups)
        #expect(try await ports.worktrees.list(projectPath: "~/App") == MockData.worktrees)
        #expect(await ports.claudeSessions.sessions() == MockData.claudeSessions)
        #expect(ports.projectDetector.isGitRepository(URL(fileURLWithPath: "/tmp")))
    }
}
