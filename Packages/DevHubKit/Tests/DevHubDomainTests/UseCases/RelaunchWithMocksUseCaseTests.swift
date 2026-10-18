import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct RelaunchWithMocksUseCaseTests {
    private let udid = "SIM-1"
    private let bundleID = "com.example.app"
    private let staging = URL(string: "https://api.staging.example.com")!

    @Test func passthroughStartsWithoutRulesAndLaunchesWithTheStubURLAndIdentity() async throws {
        let (ports, spies) = Ports.spies()
        spies.mockServer.startResult = .success(52001)

        let result = try await useCase(ports).execute(request(mode: .passthrough, set: nil)) { _ in }

        #expect(spies.mockServer.calls == [.start(udid: udid, upstream: staging, rules: [])])
        #expect(spies.simulators.calls == [
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "QA-DEVICE", "APP_BASE_URL": "http://127.0.0.1:52001"]),
        ])
        #expect(result.state == MockServerState(mode: .passthrough, setID: nil, upstreamHost: "api.staging.example.com", status: .running(port: 52001)))
        #expect(result.launch.baseURL == "http://127.0.0.1:52001")
        #expect(result.launch.identity == "QA-DEVICE")
    }

    @Test func theDefaultsOfTheProfileAreWrittenBeforeTheLaunch() async throws {
        let (ports, spies) = Ports.spies()
        let item = ProfileDefault(suite: bundleID, key: "environment", value: "staging")
        var relaunch = request(mode: .passthrough, set: nil)
        relaunch.plan.profile?.defaults = [item]

        _ = try await useCase(ports).execute(relaunch) { _ in }

        #expect(spies.simulators.calls.first == .writeDefaults(udid: udid, bundleID: bundleID, defaults: [item]))
    }

    @Test func mockModeSendsTheRulesOfTheSet() async throws {
        let (ports, spies) = Ports.spies()

        let result = try await useCase(ports).execute(request(mode: .mock, set: MockRuleFixture.set)) { _ in }

        #expect(spies.mockServer.calls == [.start(udid: udid, upstream: staging, rules: MockRuleFixture.set.rules)])
        #expect(result.state?.setID == MockRuleFixture.set.id)
    }

    @Test func offStopsTheServerAndRelaunchesWithoutTheVariable() async throws {
        let (ports, spies) = Ports.spies()

        let result = try await useCase(ports).execute(request(mode: .off, set: nil)) { _ in }

        #expect(result.state == nil)
        #expect(result.launch.baseURL == nil)
        #expect(spies.mockServer.calls == [.stop(udid: udid)])
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "QA-DEVICE"]))
    }

    @Test func productionIsRefusedBeforeAnythingStarts() async {
        let (ports, spies) = Ports.spies()
        var production = request(mode: .passthrough, set: nil)
        production.plan.profile = LaunchProfile(id: "prod", title: "Production", upstream: "https://api.example.com", production: true)

        await #expect(throws: MockServerError.productionRefused(profile: "Production")) {
            try await useCase(ports).execute(production) { _ in }
        }
        #expect(spies.mockServer.calls.isEmpty)
        #expect(spies.simulators.calls.isEmpty)
    }

    @Test func mockModeWithoutASetIsRefused() async {
        let (ports, spies) = Ports.spies()

        await #expect(throws: MockServerError.noSetChosen) {
            try await useCase(ports).execute(request(mode: .mock, set: nil)) { _ in }
        }
        #expect(spies.mockServer.calls.isEmpty)
    }

    @Test func withoutTheBaseURLVariableTheServerIsDisabled() async {
        let (ports, spies) = Ports.spies()
        var plain = request(mode: .passthrough, set: nil)
        plain.plan.baseURLVariable = nil

        await #expect(throws: MockServerError.disabled) {
            try await useCase(ports).execute(plain) { _ in }
        }
        #expect(spies.mockServer.calls.isEmpty)
    }

    @Test func serverFailureStopsBeforeTheLaunch() async {
        let (ports, spies) = Ports.spies()
        spies.mockServer.startResult = .failure(MockServerError.startFailed("busy"))

        await #expect(throws: MockServerError.startFailed("busy")) {
            try await useCase(ports).execute(request(mode: .passthrough, set: nil)) { _ in }
        }
        #expect(spies.simulators.calls.isEmpty)
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
        MockRelaunchRequest(
            udid: udid,
            bundleID: bundleID,
            plan: IdentityLaunchFixture.plan(identity: "QA-DEVICE", profile: IdentityLaunchFixture.staging, baseURLVariable: "APP_BASE_URL"),
            mode: mode,
            set: set
        )
    }
}
