import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockLaunchPreparationTests {
    private let udid = "SIM-1"
    private let qa = URL(string: "https://api-qa.example.com")!
    private let dev = URL(string: "https://api-dev.example.com")!
    private let variables = ["DEVHUB_BASE_URL": "http://127.0.0.1:52001"]

    @Test func withoutAServerNothingIsAdded() async {
        let (ports, spies) = Ports.spies()

        let outcome = await preparation(ports).prepare(udid: udid, config: .example, environment: "dev")

        #expect(outcome == .none)
        #expect(spies.mockServer.calls == [.port(udid: udid)])
    }

    @Test func withoutAConfigOnlyThePortIsPassed() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]

        let outcome = await preparation(ports).prepare(udid: udid, config: nil, environment: nil)

        #expect(outcome == MockLaunchPreparation.Outcome(environment: variables, note: "Mock server on: http://127.0.0.1:52001"))
    }

    @Test func aDifferentEnvironmentMovesTheServerToItsUpstream() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        spies.mockServer.upstreams = [udid: qa]

        let outcome = await preparation(ports).prepare(udid: udid, config: .example, environment: "dev")

        #expect(outcome.environment == variables)
        #expect(outcome.note == "Mock server on: http://127.0.0.1:52001 → api-dev.example.com")
        #expect(spies.mockServer.calls.contains(.retarget(udid: udid, upstream: dev)))
        #expect(spies.identity.calls.isEmpty)
    }

    @Test func theStoredEnvironmentIsUsedWhenNoneIsRequested() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        spies.mockServer.upstreams = [udid: dev]
        spies.identity.readResult = AppIdentity(isInstalled: true, version: "1", hasDebugHooks: true, storedEnvironment: "dev")

        let outcome = await preparation(ports).prepare(udid: udid, config: .example, environment: nil)

        #expect(outcome.environment == variables)
        #expect(spies.identity.calls == [.read(udid: udid, config: .example)])
        #expect(spies.mockServer.calls.contains { if case .retarget = $0 { true } else { false } } == false)
    }

    @Test func prodStopsTheServerAndLaunchesWithoutIt() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]

        let outcome = await preparation(ports).prepare(udid: udid, config: .example, environment: "prod")

        #expect(outcome.environment.isEmpty)
        #expect(outcome.note?.hasPrefix("Mock server stopped: ") == true)
        #expect(spies.mockServer.calls.contains(.stop(udid: udid)))
    }

    private func preparation(_ ports: Ports) -> MockLaunchPreparation {
        MockLaunchPreparation(identity: ports.identity, mockServer: ports.mockServer)
    }
}
