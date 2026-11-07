import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct ModelPreviewsTests {
    @Test func updatePreviewsBuild() {
        #expect(UpdateIndicatorModel.preview.commits.count == 2)
        #expect(UpdateIndicatorModel.previewRunning.isRunning)
        #expect(UpdateIndicatorModel.previewFailed.actionTitle == "Try Again")
        #expect(UpdateCommitRowModel.preview.hash == "a1b2c3d")
    }

    @Test func utilsPreviewsBuild() {
        #expect(VideoJobRowModel.preview.canStop)
        #expect(VideoEngineModel.preview.action == .install("Install ffmpeg"))
    }

    @Test func buildPreviewsBuild() {
        #expect(BranchChoiceModel.preview.id == "feature/login-flow")
        #expect(BuildSourceMenuModel.preview.worktrees.count == 1)
        #expect(CheckoutBadgeModel.preview.isMain == false)
        #expect(RunBarModel.preview.target?.name == "iPhone 16 Pro")
        #expect(OperationCardModel.preview.tint == .red)
        #expect(OperationsIndicatorModel.preview.isRunning)
        #expect(XcodeOptionModel.preview.title.hasPrefix("Xcode"))
        #expect(CrashBannerModel.preview.isOpen)
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
        #expect(CommitRowModel.preview.containingTags?.count == 2)
        #expect(StashRowModel.preview.isExpanded)
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
        #expect(InboxRowModel.preview.pullRequestIID == 12)
        #expect(NotificationSectionModel.preview.rows.isEmpty == false)
        #expect(ProjectCardModel.preview.statusTags.count == 3)
        #expect(QuickActionTileModel.preview.isEnabled)
        #expect(ConfigIssueRowModel.preview.message.isEmpty == false)
        #expect(ScriptRowModel.preview.isRunnable)
        #expect(ConfigActionItemModel.preview.tint == .red)
        #expect(CopyHistoryRowModel.preview.text.isEmpty == false)
    }

    @Test func otherFeaturePreviewsBuild() {
        #expect(LogLineRowModel.preview.levelTint == .red)
        #expect(OutputEntryModel.preview.canExpand)
        #expect(ScriptRowModel.preview.iconTint == .purple)
        #expect(ProjectSettingsRowModel.preview.canRemove)
        #expect(SimulatorRowModel.preview.showsActions(isHovered: false))
        #expect(AppDataFileRowModel.preview.name == "Documents")
        #expect(AppDefaultRowModel.preview.canEdit)
        #expect(PullRequestPeopleModel.preview.menus.count == 2)
        #expect(AIWriteButtonModel.preview.choices.count == 2)
        #expect(PullRequestExplainModel.preview.text != nil)
        #expect(PullRequestFileGroupChipModel.preview.isHidden)
        #expect(OperationStripModel.preview.canRetry)
        #expect(OperationsStripModel.preview.moreText != nil)
        #expect(PullRequestFileSidebarModel.preview.rows.count == 2)
        #expect(PullRequestFileSidebarRowModel.preview.isChanged)
        #expect(SplitDiffRowModel.preview.lineIDs == [1, 0])
        #expect(DiskCleanupRowModel.preview.canDelete)
        #expect(SimulatorSectionModel.preview.rows.count == 1)
        #expect(UsageMeterModel.preview.levelTint == .orange)
        #expect(UsageSummaryModel.preview.meters.count == 2)
        #expect(KeepAwakeCardModel.preview.isActive)
        #expect(WorktreeRowModel.preview.canDelete)
        #expect(WorktreeSectionModel.preview.id == "In progress")
        #expect(WorktreeLocationModel.preview.canKeepInside)
        #expect(TestRunPanelModel.preview.failures.count == 1)
        #expect(TestFailureRowModel.preview.line == 42)
        #expect(CIHistoryRowModel.preview.failedJobs.count == 1)
    }
}
