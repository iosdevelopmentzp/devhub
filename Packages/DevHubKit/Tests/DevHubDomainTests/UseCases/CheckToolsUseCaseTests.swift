import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct CheckToolsUseCaseTests {
    private let git = DoctorPolicy.tools[0]
    private let gh = DoctorPolicy.tools[3]

    @Test func aFoundToolRunsItsVersionCommand() async {
        let (ports, spies) = Ports.spies()
        spies.tools.installedTools = ["git"]
        spies.scripts.events = [.output("git version 2.50.1"), .exited(0)]

        let statuses = await UseCases(ports: ports).checkTools.execute([git, gh])

        #expect(statuses == [
            ToolStatus(tool: git, path: "/usr/local/bin/git", version: "2.50.1"),
            ToolStatus(tool: gh, path: nil, version: nil),
        ])
        #expect(spies.scripts.calls == [ScriptRunRequest(executable: "/usr/local/bin/git", arguments: ["--version"], cwd: nil, environment: [:], timeout: DoctorPolicy.timeout)])
    }

    @Test func anOutdatedToolReportsTheLatestVersion() async {
        let circleci = DoctorPolicy.tools[5]
        let (ports, spies) = Ports.spies()
        spies.tools.installedTools = ["circleci"]
        spies.scripts.events = [.output("{\"version\":\"1.13.0\",\"latest\":\"1.14.0\",\"outdated\":true}"), .exited(0)]

        let statuses = await UseCases(ports: ports).checkTools.execute([circleci])

        #expect(statuses == [ToolStatus(tool: circleci, path: "/usr/local/bin/circleci", version: "1.13.0", latestVersion: "1.14.0")])
    }
}
