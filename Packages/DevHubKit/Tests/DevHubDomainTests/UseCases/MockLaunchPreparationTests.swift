import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockLaunchPreparationTests {
    private let udid = "SIM-1"
    private let staging = URL(string: "https://api.staging.example.com")!
    private let variables = ["APP_BASE_URL": "http://127.0.0.1:52001"]

    @Test func withoutAServerNothingIsAdded() async {
        let (ports, spies) = Ports.spies()

        let outcome = await preparation(ports).prepare(udid: udid, plan: plan(IdentityLaunchFixture.staging))

        #expect(outcome == .none)
        #expect(spies.mockServer.calls == [.port(udid: udid)])
    }

    @Test func withoutTheVariableTheAppIsNotRedirected() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]

        let outcome = await preparation(ports).prepare(udid: udid, plan: .none)

        #expect(outcome == MockLaunchPreparation.Outcome(
            environment: [:],
            note: "Mock server on http://127.0.0.1:52001, but network.baseURLVariable is not set: the app is not redirected.",
            baseURL: nil
        ))
    }

    @Test func aDifferentProfileMovesTheServerToItsUpstream() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        spies.mockServer.upstreams = [udid: URL(string: "https://api.dev.example.com")!]

        let outcome = await preparation(ports).prepare(udid: udid, plan: plan(IdentityLaunchFixture.staging))

        #expect(outcome == MockLaunchPreparation.Outcome(
            environment: variables,
            note: "Mock server on: http://127.0.0.1:52001 → api.staging.example.com",
            baseURL: "http://127.0.0.1:52001"
        ))
        #expect(spies.mockServer.calls.contains(.retarget(udid: udid, upstream: staging)))
    }

    @Test func theSameUpstreamIsNotRetargeted() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        spies.mockServer.upstreams = [udid: staging]

        let outcome = await preparation(ports).prepare(udid: udid, plan: plan(IdentityLaunchFixture.staging))

        #expect(outcome.environment == variables)
        #expect(spies.mockServer.calls.contains { if case .retarget = $0 { true } else { false } } == false)
    }

    @Test func productionStopsTheServerAndLaunchesWithoutIt() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        let production = LaunchProfile(id: "prod", title: "Production", upstream: "https://api.example.com", production: true)

        let outcome = await preparation(ports).prepare(udid: udid, plan: plan(production))

        #expect(outcome.environment.isEmpty)
        #expect(outcome.note?.hasPrefix("Mock server stopped: ") == true)
        #expect(spies.mockServer.calls.contains(.stop(udid: udid)))
    }

    private func plan(_ profile: LaunchProfile?) -> LaunchPlan {
        LaunchPlan(profile: profile, identityConfig: nil, identity: nil, baseURLVariable: "APP_BASE_URL")
    }

    private func preparation(_ ports: Ports) -> MockLaunchPreparation {
        MockLaunchPreparation(mockServer: ports.mockServer)
    }
}
