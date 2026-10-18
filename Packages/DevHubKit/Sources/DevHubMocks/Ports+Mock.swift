import Foundation
import DevHubDomain

extension Ports {

    package static func mock() -> Ports {
        Ports(
            usage: MockClaudeUsageRepository(),
            copilotUsage: MockCopilotUsageRepository(),
            simulators: MockSimulatorRepository(),
            build: MockBuildRepository(),
            worktrees: MockWorktreeRepository(),
            identity: MockDeviceIdentityRepository(),
            git: MockGitRepository(),
            changes: MockGitChangesRepository(),
            logs: MockAppLogRepository(),
            mockServer: MockLocalServerRepository(),
            mockSets: MockSetStoreRepository(),
            messaging: MockSimulatorMessagingRepository(),
            codeHost: MockCodeHostRepository(),
            aiSessions: MockAISessionRepository(),
            derivedData: MockDerivedDataRepository(),
            opener: MockWorkspaceOpener(),
            attacher: MockXcodeAttacher(),
            projectDetector: MockProjectDetector(),
            reviewPrompts: MockReviewPromptRepository(),
            config: MockConfigRepository(),
            scripts: MockScriptRunner(),
            tools: MockToolLocator()
        )
    }
}
