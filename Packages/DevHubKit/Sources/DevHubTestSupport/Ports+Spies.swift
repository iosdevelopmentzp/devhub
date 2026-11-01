import DevHubDomain

package extension Ports {
    static func spies() -> (ports: Ports, spies: PortSpies) {
        let spies = PortSpies()
        let ports = Ports(
            usage: spies.usage,
            copilotUsage: spies.copilotUsage,
            simulators: spies.simulators,
            build: spies.build,
            testRuns: spies.testRuns,
            worktrees: spies.worktrees,
            launcher: spies.launcher,
            git: spies.git,
            changes: spies.changes,
            logs: spies.logs,
            mockServer: spies.mockServer,
            mockSets: spies.mockSets,
            messaging: spies.messaging,
            codeHost: spies.codeHost,
            ci: spies.ci,
            aiSessions: spies.aiSessions,
            derivedData: spies.derivedData,
            opener: spies.opener,
            attacher: spies.attacher,
            projectDetector: spies.projectDetector,
            reviewPrompts: spies.reviewPrompts,
            textFiles: spies.textFiles,
            config: spies.config,
            scripts: spies.scripts,
            tools: spies.tools,
            notifications: spies.notifications,
            sleep: spies.sleep,
            simulatorSettings: spies.simulatorSettings,
            xcodes: spies.xcodes,
            toolEnvironment: spies.toolEnvironment,
            crashes: spies.crashes,
            appData: spies.appData,
            aiText: spies.aiText,
            diskCleanup: spies.diskCleanup
        )
        return (ports, spies)
    }
}
