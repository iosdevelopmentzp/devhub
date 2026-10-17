import Foundation
import DevHubDomain

extension Ports {

    package static func live(shell: ShellRunner) -> Ports {
        let derivedData = XcodeDerivedDataRepository(shell: shell)
        let productLocator = ProductLocator(derivedData: derivedData)
        let simulators = SimctlSimulatorRepository(shell: shell)
        let identity = SimctlDeviceIdentityRepository(shell: shell, simulators: simulators)
        let attacher = AccessibilityXcodeAttacher(shell: shell)
        let build = XcodeBuildRepository(shell: shell, productLocator: productLocator)
        let worktrees = ShellWorktreeRepository(shell: shell)
        let git = ShellGitRepository(shell: shell, worktrees: worktrees)
        let home = FileManager.default.homeDirectoryForCurrentUser
        return Ports(
            usage: AnthropicUsageRepository(credentialsReader: ClaudeCredentialsReader(shell: shell)),
            simulators: simulators,
            build: build,
            worktrees: worktrees,
            identity: identity,
            git: git,
            changes: ShellGitChangesRepository(shell: shell),
            logs: SimctlAppLogRepository(shell: shell),
            mockServer: NWMockServerRepository(session: .mockForwarding()),
            mockSets: FileMockSetRepository(root: home.appendingPathComponent(".devhub/mocks", isDirectory: true)),
            messaging: SimctlMessagingRepository(shell: shell),
            mergeRequests: GlabMergeRequestRepository(client: GlabClient(shell: shell)),
            claudeSessions: ClaudeTranscriptSessionRepository(root: home.appendingPathComponent(".claude/projects", isDirectory: true)),
            derivedData: derivedData,
            opener: ShellWorkspaceOpener(shell: shell),
            attacher: attacher,
            projectDetector: XcodeProjectDetector(),
            reviewPrompts: FileReviewPromptRepository(root: home.appendingPathComponent(".devhub/prompts", isDirectory: true))
        )
    }
}
