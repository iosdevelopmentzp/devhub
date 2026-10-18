import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct PortsMockTests {
    @Test func buildsAndAnswersFromMockData() async throws {
        let ports = Ports.mock()

        #expect(try await ports.simulators.list() == MockData.simulatorGroups)
        #expect(try await ports.worktrees.list(projectPath: "~/App", settings: .standard) == MockData.worktrees)
        #expect(await ports.aiSessions.sessions() == MockData.aiSessions)
        #expect(ports.projectDetector.isGitRepository(URL(fileURLWithPath: "/tmp")))
        #expect(await ports.config.load(projectPath: "~/App") == MockData.resolvedConfig)
        #expect(MockData.resolvedConfig.issues.isEmpty)
        #expect(ports.tools.isInstalled("gh"))
    }
}
