import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct SwitchBranchUseCaseTests {
    @Test func changedFilesNeedTheStash() {
        #expect(SwitchBranchUseCase.plan(changedFiles: 0) == .switchOnly)
        #expect(SwitchBranchUseCase.plan(changedFiles: 3) == .stashSwitchPop)
    }

    @Test func switchOnlySwitches() async throws {
        let (ports, spies) = Ports.spies()

        let outcome = try await SwitchBranchUseCase(git: ports.git).execute(.switchOnly, branch: "dev", in: "/repo")

        #expect(outcome == .switched)
        #expect(spies.git.calls == [.perform(.switchBranch("dev"), path: "/repo")])
    }

    @Test func stashSwitchPopRunsTheThreeSteps() async throws {
        let (ports, spies) = Ports.spies()

        let outcome = try await SwitchBranchUseCase(git: ports.git).execute(.stashSwitchPop, branch: "dev", in: "/repo")

        #expect(outcome == .switchedWithChanges)
        #expect(spies.git.calls == [
            .perform(.stashPush(message: "DevHub: switch to dev", includeUntracked: true), path: "/repo"),
            .perform(.switchBranch("dev"), path: "/repo"),
            .perform(.stashPop(index: nil), path: "/repo"),
        ])
    }

    @Test func aFailedPopKeepsTheStash() async throws {
        let (ports, spies) = Ports.spies()
        spies.git.commandErrors = [.stashPop(index: nil): TestError.scripted("conflict")]

        let outcome = try await SwitchBranchUseCase(git: ports.git).execute(.stashSwitchPop, branch: "dev", in: "/repo")

        #expect(outcome == .switchedStashKept)
    }

    @Test func aFailedSwitchBringsTheChangesBackAndThrows() async {
        let (ports, spies) = Ports.spies()
        spies.git.commandErrors = [.switchBranch("dev"): TestError.scripted("no such branch")]

        await #expect(throws: TestError.scripted("no such branch")) {
            try await SwitchBranchUseCase(git: ports.git).execute(.stashSwitchPop, branch: "dev", in: "/repo")
        }
        #expect(spies.git.calls.last == .perform(.stashPop(index: nil), path: "/repo"))
    }
}
