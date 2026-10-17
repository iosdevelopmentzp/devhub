import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RelaunchWithMocksUseCaseTests {
    private let udid = "SIM-1"
    private let qa = URL(string: "https://api-qa.example.com")!

    @Test func passthroughStartsWithoutRulesAndLaunchesWithTheStubURLAndDeviceID() async throws {
        let (ports, spies) = Ports.spies()
        spies.mockServer.startResult = .success(52001)

        let state = try await useCase(ports).execute(request(mode: .passthrough, set: nil)) { _ in }

        #expect(spies.mockServer.calls == [.start(udid: udid, upstream: qa, rules: [])])
        #expect(spies.identity.calls == [
            .launch(udid: udid, config: .example, deviceID: "QA-DEVICE", waitForDebugger: false, environment: ["DEVHUB_BASE_URL": "http://127.0.0.1:52001"])
        ])
        #expect(state == MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api-qa.example.com", status: .running(port: 52001)))
    }

    @Test func mockModeSendsTheRulesOfTheSet() async throws {
        let (ports, spies) = Ports.spies()

        let state = try await useCase(ports).execute(request(mode: .mock, set: MockRuleFixture.set)) { _ in }

        #expect(spies.mockServer.calls == [.start(udid: udid, upstream: qa, rules: MockRuleFixture.set.rules)])
        #expect(state?.setID == MockRuleFixture.set.id)
    }

    @Test func offStopsTheServerAndRelaunchesWithoutTheVariable() async throws {
        let (ports, spies) = Ports.spies()

        let state = try await useCase(ports).execute(request(mode: .off, set: nil)) { _ in }

        #expect(state == nil)
        #expect(spies.mockServer.calls == [.stop(udid: udid)])
        #expect(spies.identity.calls == [.launch(udid: udid, config: .example, deviceID: "QA-DEVICE", waitForDebugger: false, environment: [:])])
    }

    @Test func prodIsRefusedBeforeAnythingStarts() async {
        let (ports, spies) = Ports.spies()
        var prod = request(mode: .passthrough, set: nil)
        prod.environment = "prod"

        await #expect(throws: MockServerError.prodNotSupported) {
            try await useCase(ports).execute(prod) { _ in }
        }
        #expect(spies.mockServer.calls.isEmpty)
        #expect(spies.identity.calls.isEmpty)
    }

    @Test func mockModeWithoutASetIsRefused() async {
        let (ports, spies) = Ports.spies()

        await #expect(throws: MockServerError.noSetChosen) {
            try await useCase(ports).execute(request(mode: .mock, set: nil)) { _ in }
        }
        #expect(spies.mockServer.calls.isEmpty)
    }

    @Test func projectWithoutIdentityLaunchesThroughTheSimulatorPortWhenOff() async throws {
        let (ports, spies) = Ports.spies()
        var plain = request(mode: .off, set: nil)
        plain.identity = nil

        _ = try await useCase(ports).execute(plain) { _ in }

        #expect(spies.simulators.calls == [
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: "com.example.app", waitForDebugger: false, environment: [:])
        ])
    }

    @Test func projectWithoutIdentityCannotStartTheServer() async {
        let (ports, _) = Ports.spies()
        var plain = request(mode: .passthrough, set: nil)
        plain.identity = nil

        await #expect(throws: MockServerError.noIdentityConfig) {
            try await useCase(ports).execute(plain) { _ in }
        }
    }

    @Test func serverFailureStopsBeforeTheLaunch() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.startResult = .failure(MockServerError.startFailed("busy"))

        await #expect(throws: MockServerError.startFailed("busy")) {
            try await useCase(ports).execute(request(mode: .passthrough, set: nil)) { _ in }
        }
        #expect(spies.identity.calls.isEmpty)
    }

    @Test func exchangesFromTheServerReachTheCallback() async throws {
        let (ports, spies) = Ports.spies()
        let recorder = CallbackRecorder<Int>()

        _ = try await useCase(ports).execute(request(mode: .passthrough, set: nil)) { recorder.append($0.id) }
        spies.mockServer.emit(NetworkRequestFixture.request(statusCode: 200, duration: 0.1, isFailure: false), udid: udid)

        #expect(recorder.values == [1])
    }

    private func useCase(_ ports: Ports) -> RelaunchWithMocksUseCase {
        UseCases(ports: ports).relaunchWithMocks
    }

    private func request(mode: MockMode, set: MockSet?) -> MockRelaunchRequest {
        MockRelaunchRequest(udid: udid, bundleID: "com.example.app", identity: .example, deviceID: "QA-DEVICE", environment: "qa", mode: mode, set: set)
    }
}
