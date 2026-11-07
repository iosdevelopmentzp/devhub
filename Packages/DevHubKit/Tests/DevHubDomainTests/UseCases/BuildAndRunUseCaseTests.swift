import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct BuildAndRunUseCaseTests {
    private let udid = BuildRequestFixture.udid
    private let product = BuildRequestFixture.product

    @Test func incrementalRunBootsBuildsInstallsAndLaunches() async {
        let (ports, spies) = scriptedPorts()
        let request = BuildRequestFixture.incremental

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events == [
            "step: Booting iPhone 17",
            "step: Building App",
            "output: Compiling Login.swift",
            "step: Locating app",
            "output: App: /derived/App.app",
            "step: Installing on iPhone 17",
            "step: Launching com.example.app",
            "launched: - - -",
        ])
        #expect(spies.simulators.calls == [
            .boot(udid: udid),
            .waitUntilBooted(udid: udid),
            .install(udid: udid, appPath: product.appPath),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: [:]),
        ])
        #expect(spies.build.calls == [.build(request), .locateProduct(request, hints: ["/hint/App.app"])])
        #expect(spies.attacher.calls.isEmpty)
    }

    @Test func buildOnlyStopsAfterLocatingTheApp() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.launchesApp = false

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events == [
            "step: Booting iPhone 17",
            "step: Building App",
            "output: Compiling Login.swift",
            "step: Locating app",
            "output: App: /derived/App.app",
        ])
        #expect(spies.simulators.calls == [.boot(udid: udid)])
        #expect(spies.build.calls == [.build(request), .locateProduct(request, hints: ["/hint/App.app"])])
        #expect(spies.attacher.calls.isEmpty)
    }

    @Test func bootsTheSimulatorBeforeAnythingElseWhateverItsState() async {
        let (ports, spies) = scriptedPorts()

        let result = await collect(useCase(ports).run(BuildRequestFixture.incremental))

        #expect(result.events.first == "step: Booting iPhone 17")
        #expect(spies.simulators.calls.first == .boot(udid: udid))
    }

    @Test func fullRunCleansReinstallsLaunchesWithTheIdentityAndAttaches() async {
        let (ports, spies) = scriptedPorts()
        spies.simulators.launchResult = .success(77)
        var request = BuildRequestFixture.incremental
        request.incremental = false
        request.cleanInstall = true
        request.attachDebugger = true
        request.launch = LaunchPlan(profile: nil, identityConfig: LaunchIdentityConfig(variable: "APP_DEVICE_ID", args: ["-skipOnboarding"]), identity: "QA-DEVICE", baseURLVariable: nil)

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events == [
            "step: Booting iPhone 17",
            "step: Cleaning",
            "output: Removing build folder",
            "step: Building App",
            "output: Compiling Login.swift",
            "step: Locating app",
            "output: App: /derived/App.app",
            "step: Clean install: deleting the app and resetting the simulator keychain",
            "step: Installing on iPhone 17",
            "step: Launching com.example.app · ID QA-DEVICE",
            "launched: - QA-DEVICE -",
            "output: Waiting for debugger, pid 77",
            "step: Attaching Xcode to pid 77",
        ])
        #expect(spies.build.calls == [.clean(request), .build(request), .locateProduct(request, hints: ["/hint/App.app"])])
        #expect(spies.simulators.calls == [
            .boot(udid: udid),
            .waitUntilBooted(udid: udid),
            .uninstallQuietly(udid: udid, bundleID: product.bundleID),
            .resetKeychain(udid: udid),
            .install(udid: udid, appPath: product.appPath),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: true, environment: ["APP_DEVICE_ID": "QA-DEVICE"]),
        ])
        #expect(spies.simulators.launchArguments == [["-skipOnboarding"]])
        #expect(spies.attacher.calls == [.attach(pid: 77, simulatorUDID: udid, projectPath: "/repo", container: nil)])
    }

    @Test func cleanBuildCleansBeforeBuilding() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.incremental = false

        let result = await collect(useCase(ports).run(request))

        #expect(Array(result.events.prefix(4)) == ["step: Booting iPhone 17", "step: Cleaning", "output: Removing build folder", "step: Building App"])
        #expect(spies.build.calls == [.clean(request), .build(request), .locateProduct(request, hints: ["/hint/App.app"])])
    }

    @Test func cleanInstallDeletesTheAppAndKeychainBeforeInstalling() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.cleanInstall = true

        _ = await collect(useCase(ports).run(request))

        #expect(spies.simulators.calls == [
            .boot(udid: udid),
            .waitUntilBooted(udid: udid),
            .uninstallQuietly(udid: udid, bundleID: product.bundleID),
            .resetKeychain(udid: udid),
            .install(udid: udid, appPath: product.appPath),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: [:]),
        ])
    }

    @Test func anIdentityConfigWithoutAnIDClearsTheKeptVariable() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.launch = LaunchPlan(profile: nil, identityConfig: LaunchIdentityConfig(variable: "APP_DEVICE_ID", keptVariable: "APP_KEEP_DEVICE_ID"), identity: nil, baseURLVariable: nil)

        let result = await collect(useCase(ports).run(request))

        #expect(result.events.suffix(2) == ["step: Launching com.example.app", "launched: - - -"])
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: ["APP_KEEP_DEVICE_ID": ""]))
    }

    @Test func attachWithoutIdentityLaunchesWaitingForTheDebugger() async {
        let (ports, spies) = scriptedPorts()
        spies.simulators.launchResult = .success(55)
        var request = BuildRequestFixture.incremental
        request.attachDebugger = true

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(Array(result.events.suffix(4)) == [
            "step: Launching com.example.app",
            "launched: - - -",
            "output: Waiting for debugger, pid 55",
            "step: Attaching Xcode to pid 55",
        ])
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: true, environment: [:]))
        #expect(spies.attacher.calls == [.attach(pid: 55, simulatorUDID: udid, projectPath: "/repo", container: nil)])
    }

    @Test func attachWithoutAProcessIDFails() async {
        let (ports, spies) = scriptedPorts()
        spies.simulators.launchResult = .success(nil)
        var request = BuildRequestFixture.incremental
        request.attachDebugger = true

        let result = await collect(useCase(ports).run(request))

        guard case .failed = result.error as? BuildError else {
            Issue.record("Expected BuildError.failed, got \(String(describing: result.error))")
            return
        }
        #expect(result.events.last == "launched: - - -")
        #expect(spies.attacher.calls.isEmpty)
    }

    @Test func failedBootStopsTheRun() async {
        let (ports, spies) = scriptedPorts()
        spies.simulators.bootError = SimulatorError.command("Unable to boot")

        let result = await collect(useCase(ports).run(BuildRequestFixture.incremental))

        #expect(result.error is SimulatorError)
        #expect(result.events == ["step: Booting iPhone 17"])
        #expect(spies.build.calls.isEmpty)
    }

    @Test func failedBuildStopsBeforeLocatingTheApp() async {
        let (ports, spies) = scriptedPorts()
        spies.build.buildError = BuildError.failed("2 errors")
        let request = BuildRequestFixture.incremental

        let result = await collect(useCase(ports).run(request))

        #expect(result.error is BuildError)
        #expect(result.events == ["step: Booting iPhone 17", "step: Building App", "output: Compiling Login.swift"])
        #expect(spies.build.calls == [.build(request)])
        #expect(spies.simulators.calls == [.boot(udid: udid)])
    }

    @MainActor
    @Test func cancellingTheConsumerStopsThePipeline() async throws {
        let (ports, spies) = scriptedPorts()
        let simulators = GatedSimulatorRepository()
        let gated = BuildAndRunUseCase(build: ports.build, simulators: simulators, devices: ports.devices, attacher: ports.attacher, mockServer: ports.mockServer)
        let received = CallbackRecorder<String>()

        let consumer = Task {
            for try await event in gated.run(BuildRequestFixture.incremental) {
                received.append(describe(event))
            }
        }
        try await waitUntil { received.values.isEmpty == false && simulators.calls.contains("boot") }
        consumer.cancel()
        try await waitUntil { simulators.calls.contains("boot returned") }
        _ = await consumer.result

        #expect(received.values == ["step: Booting iPhone 17"])
        #expect(simulators.calls == ["boot", "boot returned"])
        #expect(spies.build.calls.isEmpty)
    }

    @Test func runningMockServerPutsItsURLIntoTheBaseURLVariable() async {
        let (ports, spies) = scriptedPorts()
        spies.mockServer.ports = [udid: 52001]
        var request = BuildRequestFixture.incremental
        request.launch = LaunchPlan(profile: LaunchProfile(id: "staging", title: "Staging", upstream: "https://api.staging.example.com"), identityConfig: nil, identity: nil, baseURLVariable: "APP_BASE_URL")

        let result = await collect(useCase(ports).run(request))

        #expect(result.events.contains("output: Mock server on: http://127.0.0.1:52001 → api.staging.example.com"))
        #expect(result.events.last == "launched: staging - http://127.0.0.1:52001")
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: ["APP_BASE_URL": "http://127.0.0.1:52001"]))
    }

    @Test func aRunningMockServerWithoutTheVariableIsOnlyANote() async {
        let (ports, spies) = scriptedPorts()
        spies.mockServer.ports = [udid: 52001]

        let result = await collect(useCase(ports).run(BuildRequestFixture.incremental))

        #expect(result.events.contains("output: Mock server on http://127.0.0.1:52001, but network.baseURLVariable is not set: the app is not redirected."))
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: [:]))
    }

    private func scriptedPorts() -> (ports: Ports, spies: PortSpies) {
        let (ports, spies) = Ports.spies()
        spies.build.cleanEvents = [.output("Removing build folder")]
        spies.build.buildEvents = [.output("Compiling Login.swift")]
        spies.build.buildHints = ["/hint/App.app"]
        spies.build.locateProductResult = .success(BuildRequestFixture.product)
        return (ports, spies)
    }


    @Test func aLaunchProfileWritesDefaultsAndPassesItsEnvironmentAndArguments() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        let item = ProfileDefault(suite: "com.example.app", key: "environment", value: "staging")
        request.launch = LaunchPlan(profile: LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], args: ["-UITests", "YES"], defaults: [item]), identityConfig: nil, identity: nil, baseURLVariable: nil)

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events.contains("step: Writing 1 default of the launch profile"))
        #expect(spies.simulators.calls.suffix(3) == [
            .writeDefaults(udid: udid, bundleID: product.bundleID, defaults: [item]),
            .openInSimulatorApp(udid: udid),
            .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: ["API_ENV": "staging"]),
        ])
        #expect(spies.simulators.launchArguments == [["-UITests", "YES"]])
    }

    @Test func aPhysicalDeviceSkipsTheBootAndInstallsAndLaunchesWithDevicectl() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.isPhysicalDevice = true
        request.launch = LaunchPlan(profile: LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], args: ["-UITests"]), identityConfig: LaunchIdentityConfig(variable: "APP_DEVICE_ID"), identity: "QA-DEVICE", baseURLVariable: nil)

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events == [
            "step: Building App",
            "output: Compiling Login.swift",
            "step: Locating app",
            "output: App: /derived/App.app",
            "step: Installing on iPhone 17",
            "step: Launching com.example.app · ID QA-DEVICE",
            "launched: staging QA-DEVICE -",
        ])
        #expect(spies.simulators.calls.isEmpty)
        #expect(spies.devices.calls == [
            .install(udid: udid, appPath: product.appPath),
            .launch(udid: udid, bundleID: product.bundleID, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "QA-DEVICE"]),
        ])
        #expect(spies.devices.launchArguments == [["-UITests"]])
        #expect(spies.mockServer.calls.isEmpty)
    }

    @Test func cleanInstallOnADeviceRemovesTheAppAndWritesTheDefaults() async {
        let (ports, spies) = scriptedPorts()
        let item = ProfileDefault(suite: "com.example.app", key: "environment", value: "staging")
        var request = BuildRequestFixture.incremental
        request.isPhysicalDevice = true
        request.cleanInstall = true
        request.launch = LaunchPlan(profile: LaunchProfile(id: "staging", title: "Staging", defaults: [item]), identityConfig: nil, identity: nil, baseURLVariable: nil)

        let result = await collect(useCase(ports).run(request))

        #expect(result.error == nil)
        #expect(result.events.contains("step: Clean install: removing the app from iPhone 17"))
        #expect(result.events.contains("step: Writing 1 default of the launch profile"))
        #expect(spies.devices.calls == [
            .uninstall(udid: udid, bundleID: product.bundleID),
            .install(udid: udid, appPath: product.appPath),
            .writeDefaults(udid: udid, bundleID: product.bundleID, defaults: [item]),
            .launch(udid: udid, bundleID: product.bundleID, environment: [:]),
        ])
        #expect(spies.simulators.calls.isEmpty)
    }

    @Test func attachOnADeviceFailsBeforeTheInstall() async {
        let (ports, spies) = scriptedPorts()
        var request = BuildRequestFixture.incremental
        request.isPhysicalDevice = true
        request.attachDebugger = true

        let result = await collect(useCase(ports).run(request))

        guard case .attachNotAvailable? = result.error as? DeviceError else {
            Issue.record("Expected .attachNotAvailable, got \(String(describing: result.error))")
            return
        }
        #expect(spies.devices.calls.isEmpty)
        #expect(spies.attacher.calls.isEmpty)
    }

    private func useCase(_ ports: Ports) -> BuildAndRunUseCase {
        BuildAndRunUseCase(build: ports.build, simulators: ports.simulators, devices: ports.devices, attacher: ports.attacher, mockServer: ports.mockServer)
    }
}

private func describe(_ event: BuildEvent) -> String {
    switch event {
    case .step(let title, _): "step: \(title)"
    case .output(let line): "output: \(line)"
    case .launched(let record): "launched: \(record.profileID ?? "-") \(record.identity ?? "-") \(record.baseURL ?? "-")"
    case .issue(let issue): "issue: \(issue.message)"
    }
}

private func collect(_ stream: AsyncThrowingStream<BuildEvent, Error>) async -> (events: [String], error: (any Error)?) {
    var events: [String] = []
    do {
        for try await event in stream {
            events.append(describe(event))
        }
        return (events, nil)
    } catch {
        return (events, error)
    }
}
