import Foundation
import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct LaunchInstalledAppUseCaseTests {
    private let udid = IdentityLaunchFixture.udid
    private let bundleID = IdentityLaunchFixture.bundleID

    @Test func plainLaunchBootsOpensAndLaunches() async throws {
        let (ports, spies) = Ports.spies()

        let record = try await launch(ports, IdentityLaunchFixture.plain, cleanInstall: false)

        #expect(spies.simulators.calls == [
            .boot(udid: udid),
            .waitUntilBooted(udid: udid),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: bundleID, waitForDebugger: false, environment: [:]),
        ])
        #expect(spies.launcher.calls.isEmpty)
        #expect(spies.attacher.calls.isEmpty)
        #expect(record.profileID == nil)
        #expect(record.identity == nil)
    }

    @Test func cleanInstallRunsFirstThenDefaultsThenLaunchWithTheIdentity() async throws {
        let (ports, spies) = Ports.spies()
        let item = ProfileDefault(suite: "com.example.app", key: "onboarding", value: "false", type: "bool")
        var profile = IdentityLaunchFixture.staging
        profile.defaults = [item]
        var request = IdentityLaunchFixture.plain
        request.plan = IdentityLaunchFixture.plan(identity: "QA-DEVICE", profile: profile)

        let record = try await launch(ports, request, cleanInstall: true)

        #expect(spies.launcher.calls == [.cleanInstall(udid: udid, bundleID: bundleID, fallbackAppPath: "/derived/App.app")])
        #expect(spies.simulators.calls == [
            .boot(udid: udid),
            .waitUntilBooted(udid: udid),
            .writeDefaults(udid: udid, bundleID: bundleID, defaults: [item]),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "QA-DEVICE"]),
        ])
        #expect(spies.simulators.launchArguments == [["-skipOnboarding"]])
        #expect(record.profileID == "staging")
        #expect(record.identity == "QA-DEVICE")
    }

    @Test func attachesXcodeToTheLaunchedProcess() async throws {
        let (ports, spies) = Ports.spies()
        spies.simulators.launchResult = .success(4242)
        var request = IdentityLaunchFixture.plain
        request.attachDebugger = true

        _ = try await launch(ports, request, cleanInstall: false)

        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: bundleID, waitForDebugger: true, environment: [:]))
        #expect(spies.attacher.calls == [.attach(pid: 4242, simulatorUDID: udid, projectPath: "/repo", container: nil)])
    }

    @Test func attachWithoutAProcessIDFails() async {
        let (ports, spies) = Ports.spies()
        spies.simulators.launchResult = .success(nil)
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
        spies.launcher.cleanInstallError = AppLaunchError.noAppToReinstall

        await #expect(throws: AppLaunchError.self) {
            try await launch(ports, IdentityLaunchFixture.plain, cleanInstall: true)
        }
        #expect(spies.simulators.calls == [.boot(udid: udid), .waitUntilBooted(udid: udid)])
    }

    @Test func runningMockServerPutsItsURLIntoTheBaseURLVariable() async throws {
        let (ports, spies) = Ports.spies()
        spies.mockServer.ports = [udid: 52001]
        var request = IdentityLaunchFixture.plain
        request.plan = LaunchPlan(profile: IdentityLaunchFixture.staging, identityConfig: nil, identity: nil, baseURLVariable: "APP_BASE_URL")

        let record = try await launch(ports, request, cleanInstall: false)

        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_BASE_URL": "http://127.0.0.1:52001"]))
        #expect(spies.mockServer.calls.contains(.retarget(udid: udid, upstream: URL(string: "https://api.staging.example.com")!)))
        #expect(record.baseURL == "http://127.0.0.1:52001")
    }

    private func launch(_ ports: Ports, _ request: IdentityLaunch, cleanInstall: Bool) async throws -> LaunchRecord {
        try await UseCases(ports: ports).launchInstalledApp.execute(request, cleanInstall: cleanInstall)
    }

    @Test func aPhysicalDeviceLaunchesWithDevicectlOnly() async throws {
        let (ports, spies) = Ports.spies()
        var request = IdentityLaunchFixture.plain
        request.simulator = SimulatorFixture.device(udid)
        request.plan = IdentityLaunchFixture.plan(identity: "QA-DEVICE", profile: IdentityLaunchFixture.staging)

        let record = try await launch(ports, request, cleanInstall: false)

        #expect(spies.simulators.calls.isEmpty)
        #expect(spies.launcher.calls.isEmpty)
        #expect(spies.mockServer.calls.isEmpty)
        #expect(spies.devices.calls == [.launch(udid: udid, bundleID: bundleID, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "QA-DEVICE"])])
        #expect(spies.devices.launchArguments == [["-skipOnboarding"]])
        #expect(record.identity == "QA-DEVICE")
        #expect(record.baseURL == nil)
    }

    @Test func cleanInstallOnADeviceReinstallsTheLastBuildThenWritesTheDefaults() async throws {
        let (ports, spies) = Ports.spies()
        let item = ProfileDefault(suite: "com.example.app", key: "onboarding", value: "false", type: "bool")
        var profile = IdentityLaunchFixture.staging
        profile.defaults = [item]
        var request = IdentityLaunchFixture.plain
        request.simulator = SimulatorFixture.device(udid)
        request.plan = IdentityLaunchFixture.plan(identity: nil, profile: profile)

        _ = try await launch(ports, request, cleanInstall: true)

        #expect(spies.devices.calls == [
            .uninstall(udid: udid, bundleID: bundleID),
            .install(udid: udid, appPath: "/derived/App.app"),
            .writeDefaults(udid: udid, bundleID: bundleID, defaults: [item]),
            .launch(udid: udid, bundleID: bundleID, environment: ["API_ENV": "staging"]),
        ])
        #expect(spies.launcher.calls.isEmpty)
    }

    @Test func cleanInstallOnADeviceWithoutABuildFails() async {
        let (ports, spies) = Ports.spies()
        var request = IdentityLaunchFixture.plain
        request.simulator = SimulatorFixture.device(udid)
        request.fallbackAppPath = nil

        await #expect(throws: AppLaunchError.self) {
            try await launch(ports, request, cleanInstall: true)
        }
        #expect(spies.devices.calls.isEmpty)
    }

    @Test func attachOnADeviceFails() async {
        let (ports, spies) = Ports.spies()
        var request = IdentityLaunchFixture.plain
        request.simulator = SimulatorFixture.device(udid)
        request.attachDebugger = true

        await #expect(throws: DeviceError.self) {
            try await launch(ports, request, cleanInstall: false)
        }
        #expect(spies.devices.calls.isEmpty)
        #expect(spies.attacher.calls.isEmpty)
    }
}
