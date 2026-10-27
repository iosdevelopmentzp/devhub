import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct LocalBranchSectionsMapperTests {
    @Test func branchesSplitIntoCheckedOutActiveAndMerged() {
        let branches = [
            branch("visited-active"),
            branch("merged", merged: true),
            branch("in-worktree", worktree: "/wt/a"),
            branch("current"),
            branch("gone", gone: true),
            branch("older-active"),
            branch("merged-in-worktree", merged: true, worktree: "/wt/b"),
        ]

        let sections = LocalBranchSectionsMapper.sections(for: branches, currentBranch: "current", pinnedNames: [], rowModel: model)

        #expect(sections.map(\.id) == [.checkedOut, .active, .merged])
        #expect(sections.map(\.title) == ["Checked out", "Active", "Merged · safe to delete"])
        #expect(sections.map(\.detail) == ["3", "2", "2"])
        #expect(sections[0].rows.map(\.name) == ["current", "in-worktree", "merged-in-worktree"])
        #expect(sections[1].rows.map(\.name) == ["visited-active", "older-active"])
        #expect(sections[2].rows.map(\.name) == ["merged", "gone"])
    }

    @Test func pinnedBranchesGoFirstAndLeaveTheirSections() {
        let branches = [
            branch("active"),
            branch("pinned-merged", merged: true),
            branch("current"),
            branch("pinned-active"),
        ]

        let sections = LocalBranchSectionsMapper.sections(
            for: branches,
            currentBranch: "current",
            pinnedNames: ["pinned-merged", "pinned-active", "deleted"],
            rowModel: model
        )

        #expect(sections.map(\.id) == [.pinned, .checkedOut, .active])
        #expect(sections[0].title == "Pinned")
        #expect(sections[0].detail == "2")
        #expect(sections[0].rows.map(\.name) == ["pinned-merged", "pinned-active"])
        #expect(sections[1].rows.map(\.name) == ["current"])
        #expect(sections[2].rows.map(\.name) == ["active"])
    }

    @Test func emptySectionsHide() {
        let sections = LocalBranchSectionsMapper.sections(for: [branch("a"), branch("b")], currentBranch: nil, pinnedNames: [], rowModel: model)

        #expect(sections.map(\.id) == [.active])
    }

    private func branch(_ name: String, merged: Bool = false, gone: Bool = false, worktree: String? = nil) -> GitBranch {
        var branch = GitBranchFixture.feature
        branch.name = name
        branch.isMerged = merged
        branch.isGone = gone
        branch.worktreePath = worktree
        return branch
    }

    private func model(_ branch: GitBranch) -> LocalBranchRowModel {
        var model = LocalBranchRowModel.preview
        model.name = branch.name
        return model
    }
}
