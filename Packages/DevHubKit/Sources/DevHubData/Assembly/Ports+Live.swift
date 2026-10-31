import Foundation
import DevHubDomain

extension Ports {

    package static func live(shell: ShellRunner) -> Ports {
        let derivedData = XcodeDerivedDataRepository(shell: shell)
        let productLocator = ProductLocator(derivedData: derivedData)
        let simulators = SimctlSimulatorRepository(shell: shell)
        let attacher = AccessibilityXcodeAttacher(shell: shell)
        let build = XcodeBuildRepository(shell: shell, productLocator: productLocator)
        let worktrees = ShellWorktreeRepository(shell: shell)
        let git = ShellGitRepository(shell: shell, worktrees: worktrees)
        let home = FileManager.default.homeDirectoryForCurrentUser
        let tools = PathToolLocator()
        return Ports(
            usage: AnthropicUsageRepository(credentialsReader: ClaudeCredentialsReader(shell: shell)),
            copilotUsage: GitHubCopilotUsageRepository(tokenReader: CopilotTokenReader(shell: shell, tools: tools)),
            simulators: simulators,
            build: build,
            testRuns: XcodeTestRepository(shell: shell, resultsFolder: FileManager.default.temporaryDirectory.appendingPathComponent("DevHub-tests", isDirectory: true)),
            worktrees: worktrees,
            launcher: SimctlAppLaunchRepository(shell: shell),
            git: git,
            changes: ShellGitChangesRepository(shell: shell),
            logs: SimctlAppLogRepository(shell: shell),
            mockServer: NWMockServerRepository(session: .mockForwarding()),
            mockSets: FileMockSetRepository(root: home.appendingPathComponent(".devhub/mocks", isDirectory: true)),
            messaging: SimctlMessagingRepository(shell: shell),
            codeHost: RoutingCodeHostRepository(
                gitHub: GhPullRequestRepository(client: GhClient(shell: shell)),
                gitLab: GlabPullRequestRepository(client: GlabClient(shell: shell))
            ),
            aiSessions: CompositeAISessionRepository(repositories: [
                ClaudeTranscriptSessionRepository(root: home.appendingPathComponent(".claude/projects", isDirectory: true)),
                CopilotSessionRepository(root: home.appendingPathComponent(".copilot/session-state", isDirectory: true))
            ]),
            derivedData: derivedData,
            opener: ShellWorkspaceOpener(shell: shell),
            attacher: attacher,
            projectDetector: XcodeProjectDetector(),
            reviewPrompts: FileReviewPromptRepository(root: home.appendingPathComponent(".devhub/prompts", isDirectory: true)),
            textFiles: FileTextRepository(scratchRoot: home.appendingPathComponent(".devhub/scratch", isDirectory: true)),
            config: FileConfigRepository(home: home, pollInterval: .seconds(2)),
            scripts: ShellScriptRunner(shell: shell),
            tools: tools,
            notifications: SystemUserNotificationRepository(),
            sleep: IOKitSleepPreventer(),
            simulatorSettings: SimctlSettingsRepository(shell: shell)
        )
    }
}
