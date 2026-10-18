import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct UseCasesTests {
    @Test func gitUseCasesShareTheGitPort() {
        let (ports, spies) = Ports.spies()

        let useCases = UseCases(ports: ports)

        #expect(useCases.updateBranch.git as? SpyGitRepository === spies.git)
        #expect(useCases.updateBaseBranch.git as? SpyGitRepository === spies.git)
        #expect(useCases.checkOutRemoteBranch.git as? SpyGitRepository === spies.git)
        #expect(useCases.rebaseOnBase.git as? SpyGitRepository === spies.git)
        #expect(useCases.pushCurrentBranch.git as? SpyGitRepository === spies.git)
        #expect(useCases.discardChange.changes as? SpyGitRepository === spies.git)
        #expect(useCases.commit.git as? SpyGitRepository === spies.git)
    }

    @Test func worktreeUseCasesShareTheWorktreeAndDerivedDataPorts() {
        let (ports, spies) = Ports.spies()

        let useCases = UseCases(ports: ports)

        #expect(useCases.removeWorktree.worktrees as? SpyWorktreeRepository === spies.worktrees)
        #expect(useCases.removeWorktree.derivedData as? SpyDerivedDataRepository === spies.derivedData)
        #expect(useCases.cleanFinishedWorktrees.remove.worktrees as? SpyWorktreeRepository === spies.worktrees)
        #expect(useCases.cleanFinishedWorktrees.remove.derivedData as? SpyDerivedDataRepository === spies.derivedData)
        #expect(useCases.createWorktree.worktrees as? SpyWorktreeRepository === spies.worktrees)
        #expect(useCases.prepareBuildCheckout.worktrees as? SpyWorktreeRepository === spies.worktrees)
        #expect(useCases.prepareBuildCheckout.createWorktree.worktrees as? SpyWorktreeRepository === spies.worktrees)
    }

    @Test func buildUseCasesShareTheBuildSimulatorLauncherAndAttachPorts() {
        let (ports, spies) = Ports.spies()

        let useCases = UseCases(ports: ports)

        #expect(useCases.buildAndRun.build as? SpyBuildRepository === spies.build)
        #expect(useCases.buildAndRun.simulators as? SpySimulatorRepository === spies.simulators)
        #expect(useCases.buildAndRun.install.simulators as? SpySimulatorRepository === spies.simulators)
        #expect(useCases.buildAndRun.install.attacher as? SpyXcodeAttacher === spies.attacher)
        #expect(useCases.commandRun.scripts as? SpyScriptRunner === spies.scripts)
        #expect(useCases.launchInstalledApp.launcher as? SpyAppLaunchRepository === spies.launcher)
        #expect(useCases.launchInstalledApp.simulators as? SpySimulatorRepository === spies.simulators)
        #expect(useCases.launchInstalledApp.attacher as? SpyXcodeAttacher === spies.attacher)
    }
}
