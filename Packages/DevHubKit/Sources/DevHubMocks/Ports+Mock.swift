import Foundation
import DevHubDomain

extension Ports {

    package static func mock() -> Ports {
        Ports(
            usage: MockClaudeUsageRepository(),
            copilotUsage: MockCopilotUsageRepository(),
            simulators: MockSimulatorRepository(),
            build: MockBuildRepository(),
            testRuns: MockTestRunRepository(),
            worktrees: MockWorktreeRepository(),
            launcher: MockAppLaunchRepository(),
            git: MockGitRepository(),
            changes: MockGitChangesRepository(),
            logs: MockAppLogRepository(),
            mockServer: MockLocalServerRepository(),
            mockSets: MockSetStoreRepository(),
            messaging: MockSimulatorMessagingRepository(),
            codeHost: MockCodeHostRepository(),
            ci: MockCIRepository(),
            aiSessions: MockAISessionRepository(),
            derivedData: MockDerivedDataRepository(),
            opener: MockWorkspaceOpener(),
            attacher: MockXcodeAttacher(),
            projectDetector: MockProjectDetector(),
            reviewPrompts: MockReviewPromptRepository(),
            textFiles: MockTextFileRepository(),
            config: MockConfigRepository(),
            scripts: MockScriptRunner(),
            tools: MockToolLocator(),
            notifications: MockUserNotificationRepository(),
            sleep: MockSleepPreventer(),
            simulatorSettings: MockSimulatorSettingsRepository()
        )
    }
}
