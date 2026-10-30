import Foundation
import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct RunTestsUseCaseTests {
    private let request = TestRunRequest(projectPath: "/repo", container: nil, scheme: "App", configuration: "Debug", simulatorUDID: "SIM-1", simulatorName: "iPhone 17")

    @Test func bootsThenRunsAndEndsWithTheReport() async {
        let (ports, spies) = Ports.spies()
        spies.testRuns.runEvents = [.step("Running tests"), .testFinished(TestCaseResult(suite: "LoginTests", name: "testLogin", status: .passed, duration: 0.1))]
        spies.testRuns.runResult = .success(TestRunReport(status: .passed, resultBundlePath: "/tmp/App.xcresult"))

        let result = await collect(RunTestsUseCase(tests: ports.testRuns, simulators: ports.simulators).run(request))

        #expect(result.error == nil)
        #expect(result.events == [
            "step: Booting iPhone 17",
            "step: Building App for testing",
            "step: Running tests",
            "test: testLogin passed",
            "finished: passed /tmp/App.xcresult",
        ])
        #expect(spies.simulators.calls == [.boot(udid: "SIM-1")])
        #expect(spies.testRuns.calls == [.run(request)])
    }

    @Test func aFailedRunEndsTheStreamWithTheError() async {
        let (ports, spies) = Ports.spies()
        spies.testRuns.runResult = .failure(TestRunError.failed("cannot find 'x' in scope"))

        let result = await collect(RunTestsUseCase(tests: ports.testRuns, simulators: ports.simulators).run(request))

        #expect(result.error?.localizedDescription == "cannot find 'x' in scope")
        #expect(result.events.contains { $0.hasPrefix("finished") } == false)
    }

    @Test func aBootFailureStopsBeforeTheTests() async {
        let (ports, spies) = Ports.spies()
        spies.simulators.bootError = TestError.scripted("no such device")

        let result = await collect(RunTestsUseCase(tests: ports.testRuns, simulators: ports.simulators).run(request))

        #expect(result.error != nil)
        #expect(spies.testRuns.calls.isEmpty)
    }
}

private func describe(_ event: TestEvent) -> String {
    switch event {
    case .step(let title): "step: \(title)"
    case .output(let line): "output: \(line)"
    case .issue(let issue): "issue: \(issue.message)"
    case .testFinished(let result): "test: \(result.name) \(result.status)"
    case .failure(let failure): "failure: \(failure.message)"
    case .finished(let report): "finished: \(report.status) \(report.resultBundlePath ?? "-")"
    }
}

private func collect(_ stream: AsyncThrowingStream<TestEvent, Error>) async -> (events: [String], error: (any Error)?) {
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
