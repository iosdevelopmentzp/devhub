import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CleanFinishedWorktreesUseCaseTests {
    private let first = WorktreeFixture.merged(branch: "first")
    private let second = WorktreeFixture.merged(branch: "second")

    @Test func removesEveryTargetWithDerivedDataAndBranch() async {
        let (ports, spies) = Ports.spies()

        let report = await clean(ports, sizes: [:], onRemoved: { _ in })

        #expect(report.removedCount == 2)
        #expect(report.failedNames.isEmpty)
        #expect(report.summaries.map(\.outcome) == [.info, .info])
        #expect(spies.worktrees.calls == [
            .remove(first, projectPath: "/repo"),
            .deleteBranch("first", projectPath: "/repo"),
            .remove(second, projectPath: "/repo"),
            .deleteBranch("second", projectPath: "/repo"),
        ])
        #expect(spies.derivedData.calls == [.folder(checkout: first.path), .folder(checkout: second.path)])
    }

    @Test func sumsTheDerivedDataThatWasFreed() async {
        let (ports, spies) = Ports.spies()
        spies.derivedData.folderResult = URL(fileURLWithPath: "/derived/App-abc")

        let report = await clean(ports, sizes: [first.id: 1_000, second.id: 500, "/other": 9_999], onRemoved: { _ in })

        #expect(report.derivedDataBytes == 1_500)
    }

    @Test func failedRemovalsAreNamedAndNotCounted() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.removeError = TestError.scripted("locked")

        let report = await clean(ports, sizes: [first.id: 1_000], onRemoved: { _ in })

        #expect(report.removedCount == 0)
        #expect(report.failedNames == ["first", "second"])
        #expect(report.summaries.map(\.outcome) == [.failure, .failure])
        #expect(report.derivedDataBytes == 0)
    }

    @Test func callsOnRemovedOncePerTargetInOrder() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.removeError = TestError.scripted("locked")
        let removed = CallbackRecorder<Worktree.ID>()

        _ = await clean(ports, sizes: [:], onRemoved: { removed.append($0) })

        #expect(removed.values == [first.id, second.id])
    }

    @Test func emptyTargetListDoesNothing() async {
        let (ports, spies) = Ports.spies()

        let report = await CleanFinishedWorktreesUseCase(remove: removeUseCase(ports)).execute(
            [],
            projectPath: "/repo",
            derivedDataSizes: [:],
            onRemoved: { _ in }
        )

        #expect(report.removedCount == 0)
        #expect(report.summaries.isEmpty)
        #expect(spies.worktrees.calls.isEmpty)
    }

    private func clean(
        _ ports: Ports,
        sizes: [Worktree.ID: Int64],
        onRemoved: @escaping @Sendable (Worktree.ID) async -> Void
    ) async -> CleanFinishedWorktreesUseCase.Report {
        await CleanFinishedWorktreesUseCase(remove: removeUseCase(ports)).execute(
            [first, second],
            projectPath: "/repo",
            derivedDataSizes: sizes,
            onRemoved: onRemoved
        )
    }

    private func removeUseCase(_ ports: Ports) -> RemoveWorktreeUseCase {
        RemoveWorktreeUseCase(worktrees: ports.worktrees, derivedData: ports.derivedData)
    }
}
