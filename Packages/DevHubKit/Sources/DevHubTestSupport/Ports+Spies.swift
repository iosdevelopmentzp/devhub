import DevHubDomain

package extension Ports {
    static func spies() -> (ports: Ports, spies: PortSpies) {
        let spies = PortSpies()
        let ports = Ports(
            usage: spies.usage,
            simulators: spies.simulators,
            build: spies.build,
            worktrees: spies.worktrees,
            identity: spies.identity,
            git: spies.git,
            changes: spies.changes,
            logs: spies.logs,
            mockServer: spies.mockServer,
            mockSets: spies.mockSets,
            messaging: spies.messaging,
            mergeRequests: spies.mergeRequests,
            claudeSessions: spies.claudeSessions,
            derivedData: spies.derivedData,
            opener: spies.opener,
            attacher: spies.attacher,
            projectDetector: spies.projectDetector,
            reviewPrompts: spies.reviewPrompts,
            config: spies.config,
            scripts: spies.scripts,
            tools: spies.tools
        )
        return (ports, spies)
    }
}
