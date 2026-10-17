import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct ReadSimulatorStatusUseCaseTests {
    private let request = SimulatorStatusRequest(
        script: "scripts/status.sh",
        layers: [ConfigLayerInfo(layer: .project, directory: "/repo/.devhub", exists: true)],
        projectPath: "/repo",
        environment: ["DEVHUB_SIMULATOR_UDID": "sim-1"]
    )

    @Test func runsTheFirstExistingCandidateWithATimeout() async throws {
        let (ports, spies) = Ports.spies()
        spies.tools.existingFiles = ["/repo/scripts/status.sh"]
        spies.scripts.events = [.output("Environment: staging"), .exited(0)]

        let line = try await UseCases(ports: ports).readSimulatorStatus.execute(request)

        #expect(line == "Environment: staging")
        #expect(spies.scripts.calls == [ScriptRunRequest(executable: "/repo/scripts/status.sh", arguments: [], cwd: "/repo", environment: ["DEVHUB_SIMULATOR_UDID": "sim-1"], timeout: .seconds(5))])
    }

    @Test func aMissingScriptFails() async {
        let (ports, spies) = Ports.spies()

        await #expect(throws: SimulatorStatusError.notFound("scripts/status.sh")) {
            try await UseCases(ports: ports).readSimulatorStatus.execute(request)
        }
        #expect(spies.scripts.calls.isEmpty)
    }

    @Test func aNonZeroExitFailsWithTheLastLine() async {
        let (ports, spies) = Ports.spies()
        spies.tools.existingFiles = ["/repo/.devhub/scripts/status.sh"]
        spies.scripts.events = [.output("No app installed"), .exited(1)]

        await #expect(throws: SimulatorStatusError.exited(1, lastLine: "No app installed")) {
            try await UseCases(ports: ports).readSimulatorStatus.execute(request)
        }
    }

    @Test func aTimeoutBecomesAStatusError() async {
        let (ports, spies) = Ports.spies()
        spies.tools.existingFiles = ["/repo/.devhub/scripts/status.sh"]
        spies.scripts.runError = ScriptError.timedOut(.seconds(5))

        await #expect(throws: SimulatorStatusError.timedOut) {
            try await UseCases(ports: ports).readSimulatorStatus.execute(request)
        }
    }
}
