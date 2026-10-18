import DevHubDomain

package struct PortSpies: Sendable {
    package let usage = SpyClaudeUsageRepository()
    package let copilotUsage = SpyCopilotUsageRepository()
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
    package let codeHost = SpyCodeHostRepository()
    package let aiSessions = SpyAISessionRepository()
    package let derivedData = SpyDerivedDataRepository()
    package let opener = SpyWorkspaceOpener()
    package let attacher = SpyXcodeAttacher()
    package let projectDetector = SpyProjectDetector()
    package let reviewPrompts = SpyReviewPromptRepository()
    package let config = SpyConfigRepository()
    package let scripts = SpyScriptRunner()
    package let tools = SpyToolLocator()

    package init() {}
}
