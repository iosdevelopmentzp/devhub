import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RemoveWorktreeUseCaseTests {
    private let worktree = WorktreeFixture.merged(branch: "feature")
    private let folder = URL(fileURLWithPath: "/DerivedData/App-feature")

    @Test func removesWorktreeDerivedDataAndBranch() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = folder

        let summary = await remove(ports, deleteDerivedData: true, deleteBranch: true)

        #expect(spies.derivedData.calls == [.folder(checkout: worktree.path), .remove(folder)])
        #expect(spies.worktrees.calls == [.remove(worktree, projectPath: "/repo"), .deleteBranch("feature", projectPath: "/repo")])
        #expect(summary.title == "Removed worktree")
        #expect(summary.outcome == .info)
        #expect(summary.reclaimedBytes == 2_048)
        #expect(summary.detail.contains("feature"))
        #expect(summary.detail.contains("branch deleted"))
    }

    @Test func keepsDerivedDataAndBranchWhenNotAsked() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = folder

        let summary = await remove(ports, deleteDerivedData: false, deleteBranch: false)

        #expect(spies.derivedData.calls.isEmpty)
        #expect(spies.worktrees.calls == [.remove(worktree, projectPath: "/repo")])
        #expect(summary.outcome == .info)
        #expect(summary.reclaimedBytes == 0)
        #expect(summary.detail == "feature")
    }

    @Test func deletesOnlyDerivedData() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = folder

        let summary = await remove(ports, deleteDerivedData: true, deleteBranch: false)

        #expect(spies.derivedData.calls == [.folder(checkout: worktree.path), .remove(folder)])
        #expect(spies.worktrees.calls == [.remove(worktree, projectPath: "/repo")])
        #expect(summary.reclaimedBytes == 2_048)
    }

    @Test func deletesOnlyTheBranch() async {
        let (ports, spies) = Ports.spies()

        let summary = await remove(ports, deleteDerivedData: false, deleteBranch: true)

        #expect(spies.derivedData.calls.isEmpty)
        #expect(spies.worktrees.calls == [.remove(worktree, projectPath: "/repo"), .deleteBranch("feature", projectPath: "/repo")])
        #expect(summary.reclaimedBytes == 0)
    }

    @Test func noDerivedDataFolderReclaimsNothing() async {
        let (ports, spies) = Ports.spies()

        let summary = await remove(ports, deleteDerivedData: true, deleteBranch: false)

        #expect(spies.derivedData.calls == [.folder(checkout: worktree.path)])
        #expect(summary.reclaimedBytes == 0)
    }

    @Test func derivedDataThatCannotBeDeletedReclaimsNothing() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = folder
        spies.derivedData.removeError = TestError.scripted("busy")

        let summary = await remove(ports, deleteDerivedData: true, deleteBranch: false)

        #expect(summary.outcome == .info)
        #expect(summary.reclaimedBytes == 0)
        #expect(summary.detail.contains("feature"))
    }

    @Test func detachedWorktreeHasNoBranchToDelete() async {
        let (ports, spies) = Ports.spies()
        let detached = WorktreeFixture.detached(head: "ccc3333")

        _ = await RemoveWorktreeUseCase(worktrees: ports.worktrees, derivedData: ports.derivedData).execute(
            detached,
            projectPath: "/repo",
            deleteDerivedData: false,
            deleteBranch: true,
            derivedDataSize: 0
        )

        #expect(spies.worktrees.calls == [.remove(detached, projectPath: "/repo")])
    }

    @Test func unmergedBranchIsKept() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.deleteBranchError = TestError.scripted("not fully merged")

        let summary = await remove(ports, deleteDerivedData: false, deleteBranch: true)

        #expect(summary.outcome == .info)
        #expect(summary.detail.contains("branch kept"))
    }

    @Test func failedRemovalReportsAFailureAndStops() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = folder
        spies.worktrees.removeError = TestError.scripted("locked")

        let summary = await remove(ports, deleteDerivedData: true, deleteBranch: true)

        #expect(spies.worktrees.calls == [.remove(worktree, projectPath: "/repo")])
        #expect(spies.derivedData.calls == [.folder(checkout: worktree.path)])
        #expect(summary.title == "Could not remove worktree")
        #expect(summary.outcome == .failure)
        #expect(summary.reclaimedBytes == 0)
        #expect(summary.detail.contains("feature"))
    }

    private func remove(_ ports: Ports, deleteDerivedData: Bool, deleteBranch: Bool) async -> RemoveWorktreeUseCase.RemovalSummary {
        await RemoveWorktreeUseCase(worktrees: ports.worktrees, derivedData: ports.derivedData).execute(
            worktree,
            projectPath: "/repo",
            deleteDerivedData: deleteDerivedData,
            deleteBranch: deleteBranch,
            derivedDataSize: 2_048
        )
    }
}
