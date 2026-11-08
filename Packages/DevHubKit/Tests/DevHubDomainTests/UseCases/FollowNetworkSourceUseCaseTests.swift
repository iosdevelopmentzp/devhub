import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct FollowNetworkSourceUseCaseTests {
    private let request = NetworkSourceRequest(
        script: "network/source.sh",
        layers: [ConfigLayerInfo(layer: .project, directory: "/repo/.devhub", exists: true)],
        projectPath: "/repo",
        environment: ["DEVHUB_SIMULATOR_UDID": "sim-1"]
    )

    private func events(_ ports: Ports) async throws -> [NetworkSourceEvent] {
        var events: [NetworkSourceEvent] = []
        for try await event in UseCases(ports: ports).followNetworkSource.execute(request) {
            events.append(event)
        }
        return events
    }

    private func request(id: Int) -> NetworkRequest {
        NetworkRequest(id: id, method: "GET", url: "https://api.example.com/v1/x", path: "/v1/x", host: "api.example.com", statusCode: 200, statusText: "", startedAt: nil, duration: nil, requestBody: "", responseBody: "", responseHeaders: [], error: nil, isFailure: false, origin: .sourceScript)
    }

    @Test func runsTheScriptOfTheConfigLayerWithoutATimeout() async throws {
        let (ports, spies) = Ports.spies()
        spies.tools.existingFiles = ["/repo/.devhub/network/source.sh"]
        spies.networkSource.events = [.output("reading the log"), .request(request(id: 1)), .error("bad line"), .exited(0)]

        let events = try await events(ports)

        #expect(events == [.request(request(id: 1)), .error("bad line")])
        #expect(spies.networkSource.calls == [ScriptRunRequest(executable: "/repo/.devhub/network/source.sh", arguments: [], cwd: "/repo", environment: ["DEVHUB_SIMULATOR_UDID": "sim-1"], timeout: nil)])
    }

    @Test func aMissingScriptFails() async {
        let (ports, spies) = Ports.spies()

        await #expect(throws: NetworkSourceError.notFound("network/source.sh")) {
            try await events(ports)
        }
        #expect(spies.networkSource.calls.isEmpty)
    }

    @Test func aNonZeroExitFailsWithTheLastLine() async {
        let (ports, spies) = Ports.spies()
        spies.tools.existingFiles = ["/repo/network/source.sh"]
        spies.networkSource.events = [.output("no log file"), .output(""), .exited(3)]

        await #expect(throws: NetworkSourceError.exited(3, lastLine: "no log file")) {
            try await events(ports)
        }
    }
}
