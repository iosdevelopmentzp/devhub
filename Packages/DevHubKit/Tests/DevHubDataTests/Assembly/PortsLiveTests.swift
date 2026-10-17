import DevHubDomain
import DevHubTestSupport
import Testing
@testable import DevHubData

@Suite struct PortsLiveTests {
    @Test func buildsWithoutRunningAProcess() {
        let recorder = SpyCommandRecorder()

        let ports = Ports.live(shell: ShellRunner(recorder: recorder))

        #expect(ports.git is ShellGitRepository)
        #expect(ports.worktrees is ShellWorktreeRepository)
        #expect(ports.simulators is SimctlSimulatorRepository)
        #expect(ports.mockServer is NWMockServerRepository)
        #expect(ports.mockSets is FileMockSetRepository)
        #expect(recorder.events.isEmpty)
    }
}
