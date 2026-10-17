import Foundation
import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct LaunchInstalledAppUseCaseTests {
    private let udid = IdentityLaunchFixture.udid

    @Test func plainLaunchOnlyLaunches() async throws {
        let (ports, spies) = Ports.spies()

        try await launch(ports, IdentityLaunchFixture.plain, cleanInstall: false)

        #expect(spies.identity.calls == [.launch(udid: udid, config: .example, deviceID: nil, waitForDebugger: false, environment: [:])])
        #expect(spies.attacher.calls.isEmpty)
    }

    @Test func cleanInstallRunsFirstThenEnvironmentThenLaunchWithTheDeviceID() async throws {
        let (ports, spies) = Ports.spies()
        var request = IdentityLaunchFixture.plain
        request.deviceID = "QA-DEVICE"
        request.environment = "qa"

        try await launch(ports, request, cleanInstall: true)

        #expect(spies.identity.calls == [
            .cleanInstall(udid: udid, config: .example, fallbackAppPath: "/derived/App.app"),
            .setEnvironment("qa", udid: udid, config: .example),
            .launch(udid: udid, config: .example, deviceID: "QA-DEVICE", waitForDebugger: false, environment: [:]),
        ])
    }

    @Test func attachesXcodeToTheLaunchedProcess() async throws {
        let (ports, spies) = Ports.spies()
        spies.identity.launchResult = .success(4242)
        var request = IdentityLaunchFixture.plain
        request.attachDebugger = true

        try await launch(ports, request, cleanInstall: false)

        #expect(spies.identity.calls == [.launch(udid: udid, config: .example, deviceID: nil, waitForDebugger: true, environment: [:])])
        #expect(spies.attacher.calls == [.attach(pid: 4242, simulatorUDID: udid, projectPath: "/repo")])
    }

    @Test func attachWithoutAProcessIDFails() async {
        let (ports, spies) = Ports.spies()
        spies.identity.launchResult = .success(nil)
        var request = IdentityLaunchFixture.plain
        request.attachDebugger = true

        let error = await #expect(throws: XcodeAttachError.self) {
            try await launch(ports, request, cleanInstall: false)
        }

        guard case .script = error else {
            Issue.record("Expected .script, got \(String(describing: error))")
            return
        }
        #expect(spies.attacher.calls.isEmpty)
    }

    @Test func failedCleanInstallStopsBeforeLaunch() async {
        let (ports, spies) = Ports.spies()
        spies.identity.cleanInstallError = DeviceIdentityError.noAppToReinstall

        await #expect(throws: DeviceIdentityError.self) {
            try await launch(ports, IdentityLaunchFixture.plain, cleanInstall: true)
        }
        #expect(spies.identity.calls == [.cleanInstall(udid: udid, config: .example, fallbackAppPath: "/derived/App.app")])
    }

    @Test func runningMockServerKeepsTheStubURLOnTheLaunch() async throws {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]

        try await launch(ports, IdentityLaunchFixture.plain, cleanInstall: false)

        #expect(spies.identity.calls == [
            .read(udid: udid, config: .example),
            .launch(udid: udid, config: .example, deviceID: nil, waitForDebugger: false, environment: ["DEVHUB_BASE_URL": "http://127.0.0.1:52001"])
        ])
        #expect(spies.mockServer.calls.contains(.retarget(udid: udid, upstream: URL(string: "https://api-qa.example.com")!)))
    }

    private func launch(_ ports: Ports, _ request: IdentityLaunch, cleanInstall: Bool) async throws {
        try await LaunchInstalledAppUseCase(identity: ports.identity, attacher: ports.attacher, mockServer: ports.mockServer).execute(
            request,
            config: .example,
            cleanInstall: cleanInstall
        )
    }
}
