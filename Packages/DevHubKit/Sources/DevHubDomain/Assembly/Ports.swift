import Foundation

package struct Ports: Sendable {
    package let usage: any ClaudeUsageRepository
    package let copilotUsage: any CopilotUsageRepository
    package let simulators: any SimulatorRepository
    package let build: any BuildRepository
    package let worktrees: any WorktreeRepository
    package let launcher: any AppLaunchRepository
    package let git: any GitRepository
    package let changes: any GitChangesRepository
    package let logs: any AppLogRepository
    package let mockServer: any MockServerRepository
    package let mockSets: any MockSetRepository
    package let messaging: any SimulatorMessagingRepository
    package let codeHost: any CodeHostRepository
    package let aiSessions: any AISessionRepository
    package let derivedData: any DerivedDataRepository
    package let opener: any WorkspaceOpening
    package let attacher: any XcodeAttaching
    package let projectDetector: any ProjectDetecting
    package let reviewPrompts: any ReviewPromptRepository
    package let config: any ConfigRepository
    package let scripts: any ScriptRunning
    package let tools: any ToolLocating
    package let notifications: any UserNotificationRepository

    package init(
        usage: any ClaudeUsageRepository,
        copilotUsage: any CopilotUsageRepository,
        simulators: any SimulatorRepository,
        build: any BuildRepository,
        worktrees: any WorktreeRepository,
        launcher: any AppLaunchRepository,
        git: any GitRepository,
        changes: any GitChangesRepository,
        logs: any AppLogRepository,
        mockServer: any MockServerRepository,
        mockSets: any MockSetRepository,
        messaging: any SimulatorMessagingRepository,
        codeHost: any CodeHostRepository,
        aiSessions: any AISessionRepository,
        derivedData: any DerivedDataRepository,
        opener: any WorkspaceOpening,
        attacher: any XcodeAttaching,
        projectDetector: any ProjectDetecting,
        reviewPrompts: any ReviewPromptRepository,
        config: any ConfigRepository,
        scripts: any ScriptRunning,
        tools: any ToolLocating,
        notifications: any UserNotificationRepository
    ) {
        self.usage = usage
        self.copilotUsage = copilotUsage
        self.simulators = simulators
        self.build = build
        self.worktrees = worktrees
        self.launcher = launcher
        self.git = git
        self.changes = changes
        self.logs = logs
        self.mockServer = mockServer
        self.mockSets = mockSets
        self.messaging = messaging
        self.codeHost = codeHost
        self.aiSessions = aiSessions
        self.derivedData = derivedData
        self.opener = opener
        self.attacher = attacher
        self.projectDetector = projectDetector
        self.reviewPrompts = reviewPrompts
        self.config = config
        self.scripts = scripts
        self.tools = tools
        self.notifications = notifications
    }
}
