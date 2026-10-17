import Foundation

package struct Ports: Sendable {
    package let usage: any ClaudeUsageRepository
    package let simulators: any SimulatorRepository
    package let build: any BuildRepository
    package let worktrees: any WorktreeRepository
    package let identity: any DeviceIdentityRepository
    package let git: any GitRepository
    package let changes: any GitChangesRepository
    package let logs: any AppLogRepository
    package let mockServer: any MockServerRepository
    package let mockSets: any MockSetRepository
    package let messaging: any SimulatorMessagingRepository
    package let mergeRequests: any MergeRequestRepository
    package let claudeSessions: any ClaudeSessionRepository
    package let derivedData: any DerivedDataRepository
    package let opener: any WorkspaceOpening
    package let attacher: any XcodeAttaching
    package let projectDetector: any ProjectDetecting
    package let reviewPrompts: any ReviewPromptRepository

    package init(
        usage: any ClaudeUsageRepository,
        simulators: any SimulatorRepository,
        build: any BuildRepository,
        worktrees: any WorktreeRepository,
        identity: any DeviceIdentityRepository,
        git: any GitRepository,
        changes: any GitChangesRepository,
        logs: any AppLogRepository,
        mockServer: any MockServerRepository,
        mockSets: any MockSetRepository,
        messaging: any SimulatorMessagingRepository,
        mergeRequests: any MergeRequestRepository,
        claudeSessions: any ClaudeSessionRepository,
        derivedData: any DerivedDataRepository,
        opener: any WorkspaceOpening,
        attacher: any XcodeAttaching,
        projectDetector: any ProjectDetecting,
        reviewPrompts: any ReviewPromptRepository
    ) {
        self.usage = usage
        self.simulators = simulators
        self.build = build
        self.worktrees = worktrees
        self.identity = identity
        self.git = git
        self.changes = changes
        self.logs = logs
        self.mockServer = mockServer
        self.mockSets = mockSets
        self.messaging = messaging
        self.mergeRequests = mergeRequests
        self.claudeSessions = claudeSessions
        self.derivedData = derivedData
        self.opener = opener
        self.attacher = attacher
        self.projectDetector = projectDetector
        self.reviewPrompts = reviewPrompts
    }
}
