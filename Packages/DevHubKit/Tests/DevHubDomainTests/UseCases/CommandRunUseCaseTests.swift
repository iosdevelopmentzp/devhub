import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CommandRunUseCaseTests {
    private let udid = BuildRequestFixture.udid
    private let product = BuildRequestFixture.product

    @Test func theAppDirectiveInstallsAndLaunchesTheApp() async {
        let (ports, spies) = Ports.spies()
        spies.scripts.events = [.output("Compiling"), .output(#"@devhub {"progress": "Half", "fraction": 0.5}"#), .output(#"@devhub {"app": "build/App.app"}"#), .exited(0)]
        spies.build.locateProductResult = .success(product)

        let result = await collect(useCase(ports).run(request(build: "scripts/build.sh", run: nil)))

        #expect(result.error == nil)
        #expect(spies.scripts.calls.map(\.executable) == ["/repo/scripts/build.sh"])
        #expect(spies.scripts.calls.first?.cwd == "/repo")
        #expect(spies.scripts.calls.first?.environment["DEVHUB_SIMULATOR_UDID"] == udid)
        #expect(spies.build.calls == [.product(appPath: "/repo/build/App.app")])
        #expect(result.events.contains("step: Half"))
        #expect(result.events.contains("output: Compiling"))
        #expect(spies.simulators.calls.first == .boot(udid: udid))
        #expect(spies.simulators.calls.contains(.install(udid: udid, appPath: product.appPath)))
        #expect(spies.simulators.calls.last == .launch(udid: udid, bundleID: product.bundleID, waitForDebugger: false, environment: [:]))
    }

    @Test func bothCommandsRunInOrder() async {
        let (ports, spies) = Ports.spies()

        let result = await collect(useCase(ports).run(request(build: "build.sh", run: "/abs/run.sh")))

        #expect(result.error == nil)
        #expect(spies.scripts.calls.map(\.executable) == ["/repo/build.sh", "/abs/run.sh"])
        #expect(result.events.last == "output: No app directive: the commands launch the app themselves.")
        #expect(spies.simulators.calls == [.boot(udid: udid)])
    }

    @Test func aFailingCommandStopsTheRun() async {
        let (ports, spies) = Ports.spies()
        spies.scripts.events = [.exited(2)]

        let result = await collect(useCase(ports).run(request(build: "build.sh", run: "run.sh")))

        #expect(result.error?.localizedDescription == "build.command exited with code 2.")
        #expect(spies.scripts.calls.count == 1)
    }

    @Test func anErrorDirectiveFailsTheRun() async {
        let (ports, spies) = Ports.spies()
        spies.scripts.events = [.output(#"@devhub {"error": "Signing failed"}"#), .exited(0)]

        let result = await collect(useCase(ports).run(request(build: nil, run: "run.sh")))

        #expect(result.error?.localizedDescription == "Signing failed")
    }

    @Test func buildOnlyRunsTheBuildCommandAndStops() async {
        let (ports, spies) = Ports.spies()
        spies.scripts.events = [.output(#"@devhub {"app": "build/App.app"}"#), .exited(0)]

        let result = await collect(useCase(ports).run(request(build: "build.sh", run: "run.sh", launchesApp: false)))

        #expect(result.error == nil)
        #expect(spies.scripts.calls.map(\.executable) == ["/repo/build.sh"])
        #expect(result.events.last == "output: App: /repo/build/App.app")
        #expect(spies.simulators.calls == [.boot(udid: udid)])
        #expect(spies.build.calls.isEmpty)
    }

    @Test func buildOnlyWithoutAnAppDirectiveReportsTheEnd() async {
        let (ports, spies) = Ports.spies()

        let result = await collect(useCase(ports).run(request(build: "build.sh", run: "run.sh", launchesApp: false)))

        #expect(spies.scripts.calls.map(\.executable) == ["/repo/build.sh"])
        #expect(result.events.last == "output: build.command finished.")
    }

    @Test func buildOnlyWithoutABuildCommandRunsNothing() async {
        let (ports, spies) = Ports.spies()

        let result = await collect(useCase(ports).run(request(build: nil, run: "run.sh", launchesApp: false)))

        #expect(spies.scripts.calls.isEmpty)
        #expect(result.events.last == "output: No build.command: nothing to build.")
    }

    private func request(build: String?, run: String?, launchesApp: Bool = true) -> CommandRunRequest {
        var target = BuildRequestFixture.incremental
        target.launchesApp = launchesApp
        return CommandRunRequest(buildCommand: build, runCommand: run, folder: "/repo", environment: ["DEVHUB_SIMULATOR_UDID": udid], target: target)
    }

    private func useCase(_ ports: Ports) -> CommandRunUseCase {
        UseCases(ports: ports).commandRun
    }
}

private func collect(_ stream: AsyncThrowingStream<BuildEvent, Error>) async -> (events: [String], error: (any Error)?) {
    var events: [String] = []
    do {
        for try await event in stream {
            switch event {
            case .step(let title, _): events.append("step: \(title)")
            case .output(let line): events.append("output: \(line)")
            case .launched: events.append("launched")
            case .issue(let issue): events.append("issue: \(issue.message)")
            }
        }
        return (events, nil)
    } catch {
        return (events, error)
    }
}
