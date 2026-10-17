import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct WorktreeSectionsMapperTests {
    @Test func sectionsInFixedOrderWithTitles() {
        var merged = rename(WorktreeFixture.linked, id: "merged")
        merged.isMerged = true
        var missing = rename(WorktreeFixture.linked, id: "missing")
        missing.isMissing = true

        let sections = map([missing, merged, WorktreeFixture.linked, WorktreeFixture.main])

        #expect(sections.map(\.title) == [
            "Main checkout",
            "In progress",
            "Finished · merged or remote branch deleted",
            "Missing folder"
        ])
        #expect(sections.map(\.id) == sections.map(\.title))
        #expect(sections[0].rows.map(\.id) == [WorktreeFixture.main.id])
        #expect(sections[1].rows.map(\.id) == [WorktreeFixture.linked.id])
        #expect(sections[2].rows.map(\.id) == ["merged"])
        #expect(sections[3].rows.map(\.id) == ["missing"])
    }

    @Test func emptySectionsAreDropped() {
        #expect(map([WorktreeFixture.linked]).map(\.title) == ["In progress"])
        #expect(map([]).isEmpty)
    }

    @Test func groupsAreSortedByLastActivityNewestFirst() {
        var old = rename(WorktreeFixture.linked, id: "old")
        old.lastActivity = Date(timeIntervalSince1970: 100)
        var new = rename(WorktreeFixture.linked, id: "new")
        new.lastActivity = Date(timeIntervalSince1970: 300)
        var never = rename(WorktreeFixture.linked, id: "never")
        never.lastActivity = nil
        var finishedOld = rename(old, id: "finished-old")
        finishedOld.isUpstreamGone = true
        var finishedNew = rename(new, id: "finished-new")
        finishedNew.isUpstreamGone = true

        let sections = map([never, old, finishedOld, new, finishedNew])

        #expect(sections[0].rows.map(\.id) == ["new", "old", "never"])
        #expect(sections[1].rows.map(\.id) == ["finished-new", "finished-old"])
    }

    @Test func missingFinishedWorktreeGoesToMissing() {
        var worktree = rename(WorktreeFixture.linked, id: "gone")
        worktree.isMissing = true
        worktree.isMerged = true

        #expect(map([worktree]).map(\.title) == ["Missing folder"])
    }

    private func map(_ worktrees: [Worktree]) -> [WorktreeSectionModel] {
        WorktreeSectionsMapper.sections(for: worktrees) { worktree in
            WorktreeRowMapper.model(
                for: worktree,
                baseBranch: "origin/dev",
                mainCheckoutPath: WorktreeFixture.mainPath,
                derivedDataSize: nil,
                isBusy: false,
                isBootstrapping: false,
                isBuildSource: false,
                buildIsRunning: false,
                configActions: []
            )
        }
    }

    private func rename(_ worktree: Worktree, id: String) -> Worktree {
        Worktree(
            id: id,
            path: "/tmp/\(id)",
            branch: worktree.branch,
            head: worktree.head,
            kind: worktree.kind,
            isLocked: worktree.isLocked,
            isMissing: worktree.isMissing,
            changedFiles: worktree.changedFiles,
            upstream: worktree.upstream,
            isUpstreamGone: worktree.isUpstreamGone,
            ahead: worktree.ahead,
            behind: worktree.behind,
            isMerged: worktree.isMerged,
            lastCommit: worktree.lastCommit,
            lastActivity: worktree.lastActivity,
            needsBootstrap: worktree.needsBootstrap
        )
    }
}
