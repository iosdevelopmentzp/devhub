import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct ModelPreviewsTests {
    @Test func buildPreviewsBuild() {
        #expect(BranchChoiceModel.preview.id == "feature/login-flow")
        #expect(BuildSourceMenuModel.preview.worktrees.count == 1)
        #expect(RunBarModel.preview.target?.name == "iPhone 16 Pro")
    }

    @Test func claudePreviewsBuild() {
        #expect(AISessionRowModel.preview.providerTag.text == "Claude")
    }

    @Test func deviceIdentityPreviewsBuild() {
        #expect(CleanInstallNoteModel.preview.iconTint == .secondary)
        #expect(IdentityPanelModel.preview.isInstalled)
        #expect(IdentitySummaryModel.preview.userIcon == "person.fill")
        #expect(LaunchIdentityModel.preview.idPrefix == "devhub-")
    }

    @Test func gitPreviewsBuild() {
        #expect(CommitBoxModel.preview.canCommit)
        #expect(CommitRowModel.preview.shortHash == "a1b2c3d")
        #expect(DiffLineModel.preview.tint == .green)
        #expect(DiffModel.preview != .loading)
        #expect(FileChangeGroupModel.preview.changes.count == 1)
        #expect(FileChangeRowModel.preview.isExpanded)
        #expect(GitHeaderActionModel.preview.id == .fetch)
        #expect(GitHeaderModel.preview.actions == [.preview])
        #expect(LocalBranchRowModel.preview.canSwitch)
        #expect(PullRequestLineModel.preview.canRefresh)
        #expect(RemoteBranchRowModel.preview.localName == "feature/ABC-2401-gifts")
    }

    @Test func networkPreviewsBuild() {
        #expect(NetworkRequestRowModel.preview.methodTint == .blue)
        #expect(NetworkRequestDetailModel.preview.canCopyResponseBody)
        #expect(NetworkRequestDetailModel.preview.canMock)
        #expect(NetworkRequestRowModel.preview.tags == [NetworkRequestRowMapper.mockedTag])
        #expect(MockServerBarModel.preview.showsSetPicker)
        #expect(MockRuleRowModel.preview.isEnabled)
    }

    @Test func homePreviewsBuild() {
        #expect(ActivityRowModel.preview.dotTint == .green)
        #expect(ProjectCardModel.preview.statusTags.count == 3)
        #expect(QuickActionTileModel.preview.isEnabled)
        #expect(ConfigIssueRowModel.preview.message.isEmpty == false)
        #expect(ScriptRowModel.preview.isRunnable)
        #expect(ConfigActionItemModel.preview.tint == .red)
    }

    @Test func otherFeaturePreviewsBuild() {
        #expect(LogLineRowModel.preview.levelTint == .red)
        #expect(OutputEntryModel.preview.canExpand)
        #expect(ScriptRowModel.preview.iconTint == .purple)
        #expect(ProjectSettingsRowModel.preview.canRemove)
        #expect(SimulatorRowModel.preview.showsActions(isHovered: false))
        #expect(SimulatorSectionModel.preview.rows.count == 1)
        #expect(UsageMeterModel.preview.levelTint == .orange)
        #expect(UsageSummaryModel.preview.meters.count == 2)
        #expect(KeepAwakeCardModel.preview.isActive)
        #expect(WorktreeRowModel.preview.canDelete)
        #expect(WorktreeSectionModel.preview.id == "In progress")
        #expect(TestRunPanelModel.preview.failures.count == 1)
        #expect(TestFailureRowModel.preview.line == 42)
    }
}
