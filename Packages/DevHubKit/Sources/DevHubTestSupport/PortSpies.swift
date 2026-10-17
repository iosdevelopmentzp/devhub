import DevHubDomain

package struct PortSpies: Sendable {
    package let usage = SpyClaudeUsageRepository()
    package let simulators = SpySimulatorRepository()
    package let build = SpyBuildRepository()
    package let worktrees = SpyWorktreeRepository()
    package let identity = SpyDeviceIdentityRepository()
    package let git = SpyGitRepository()
    package let changes = SpyGitChangesRepository()
    package let logs = SpyAppLogRepository()
    package let mockServer = SpyMockServerRepository()
    package let mockSets = SpyMockSetRepository()
    package let messaging = SpySimulatorMessagingRepository()
    package let mergeRequests = SpyMergeRequestRepository()
    package let claudeSessions = SpyClaudeSessionRepository()
    package let derivedData = SpyDerivedDataRepository()
    package let opener = SpyWorkspaceOpener()
    package let attacher = SpyXcodeAttacher()
    package let projectDetector = SpyProjectDetector()
    package let reviewPrompts = SpyReviewPromptRepository()

    package init() {}
}
