import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct ShellRunnerIntegrationTests {
    private let recorder = SpyCommandRecorder()
    private let runner: ShellRunner

    init() {
        runner = ShellRunner(recorder: recorder)
    }

    @Test func capturesStdoutAndExitCode() async throws {
        let result = try await runner.run("/bin/echo", ["hello"], cwd: nil)

        #expect(result.stdout == "hello\n")
        #expect(result.stderr == "")
        #expect(result.exitCode == 0)
    }

    @Test func nonZeroExitIsAResultNotAnError() async throws {
        let result = try await runner.run("sh", ["-c", "echo err 1>&2; exit 3"], cwd: nil)

        #expect(result.stdout == "")
        #expect(result.stderr == "err\n")
        #expect(result.exitCode == 3)
        #expect(result.failureMessage == "err")
    }

    @Test func expandsTildeInWorkingDirectory() async throws {
        let result = try await runner.run("pwd", [], cwd: "~")

        #expect(resolved(result.stdout.trimmed) == resolved(("~" as NSString).expandingTildeInPath))
    }

    @Test func runsInTheGivenWorkingDirectory() async throws {
        let directory = try TemporaryDirectory()

        let result = try await runner.run("pwd", [], cwd: directory.url.path)

        #expect(resolved(result.stdout.trimmed) == resolved(directory.url.path))
    }

    @Test func mergesEnvironmentIntoTheProcessEnvironment() async throws {
        let result = try await runner.run("sh", ["-c", "echo $DEVHUB_TEST; echo $PATH"], cwd: nil, environment: ["DEVHUB_TEST": "merged"])
        let lines = result.stdout.split(separator: "\n").map(String.init)

        #expect(lines.first == "merged")
        #expect(lines.last?.hasPrefix("/opt/homebrew/bin:/usr/local/bin:") == true)
    }

    @Test func recordsStartedOutputFinishedInOrder() async throws {
        _ = try await runner.run("/bin/echo", ["hello world"], cwd: "/tmp")

        let events = recorder.events
        #expect(events.map(\.stage) == ["started", "output", "finished"])
        #expect(Set(events.map(\.id)).count == 1)
        #expect(events.first?.startedCommand == "/bin/echo 'hello world'")
        #expect(events.first?.startedKind == .action)
        #expect(events[1].outputLines == ["hello world", ""])
        #expect(events.last?.finishedExitCode == 0)
        #expect(events.last?.finishedError == nil)
    }

    @Test func startedCarriesTheCurrentOperation() async throws {
        let operationID = UUID()

        try await OperationScope.$current.withValue(operationID) {
            _ = try await runner.run("true", [], cwd: nil)
            _ = try await runner.stream("true", [], cwd: nil) { _ in }
        }
        _ = try await runner.run("true", [], cwd: nil)

        let started = recorder.events.filter { $0.stage == "started" }
        #expect(started.map(\.startedOperationID) == [operationID, operationID, nil])
    }

    @Test func silentCommandRecordsNoOutput() async throws {
        _ = try await runner.run("true", [], cwd: nil)

        #expect(recorder.events.map(\.stage) == ["started", "finished"])
    }

    @Test func missingExecutableFinishesWithExitCode127() async throws {
        let result = try await runner.run("devhub-no-such-tool-\(UUID().uuidString.prefix(8))", [], cwd: nil)

        #expect(result.exitCode == 127)
        #expect(recorder.events.last?.finishedExitCode == 127)
    }

    @Test func securityIsSecretAndRecordsNoOutput() async throws {
        let result = try await runner.run("security", ["help"], cwd: nil)

        let events = recorder.events
        #expect(result.exitCode == 0)
        #expect(events.first?.startedKind == .secret)
        #expect(events.map(\.stage) == ["started", "finished"])
        #expect(events.contains { $0.outputLines != nil } == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func manyParallelRunsAllFinish() async throws {
        let results = try await withThrowingTaskGroup(of: ShellResult.self) { [runner] group in
            for index in 0..<100 {
                group.addTask {
                    try await runner.run("sh", ["-c", "sleep 0.2; echo out\(index); echo err\(index) 1>&2"], cwd: nil)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(results.count == 100)
        #expect(results.allSatisfy { $0.exitCode == 0 })
        #expect(Set(results.map(\.stdout)).count == 100)
        #expect(Set(results.map(\.stderr)).count == 100)
    }

    @Test(.timeLimit(.minutes(1)))
    func readsLargeStdoutAndStderrTogether() async throws {
        let result = try await runner.run("sh", ["-c", "head -c 300000 /dev/zero | tr '\\0' a; head -c 300000 /dev/zero | tr '\\0' b 1>&2"], cwd: nil)

        #expect(result.stdout.utf8.count == 300_000)
        #expect(result.stderr.utf8.count == 300_000)
        #expect(result.exitCode == 0)
    }

    @Test func missingWorkingDirectoryThrows() async throws {
        await #expect(throws: (any Error).self) {
            try await runner.run("pwd", [], cwd: "/devhub-no-such-folder-\(UUID().uuidString.prefix(8))")
        }
        #expect(recorder.events.last?.finishedExitCode == nil)
    }

    @Test func streamDeliversLinesAndReturnsExitCode() async throws {
        let collector = LineCollector()

        let status = try await runner.stream("sh", ["-c", "echo one; echo two; exit 4"], cwd: nil) { collector.add($0) }

        #expect(status == 4)
        #expect(collector.lines == ["one", "two"])
        let events = recorder.events
        #expect(events.first?.stage == "started")
        #expect(events.compactMap(\.outputLines).flatMap { $0 } == ["one", "two"])
        #expect(events.last?.finishedExitCode == 4)
        #expect(events.last?.finishedError == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func manyParallelStreamsAllFinish() async throws {
        let statuses = try await withThrowingTaskGroup(of: Int32.self) { [runner] group in
            for index in 0..<100 {
                group.addTask {
                    try await runner.stream("sh", ["-c", "echo line\(index); exit \(index % 4)"], cwd: nil) { _ in }
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(statuses.count == 100)
        #expect(statuses.sorted() == (0..<100).map { Int32($0 % 4) }.sorted())
    }

    @Test func streamRecordsReadCommandsAsActions() async throws {
        _ = try await runner.stream("git", ["rev-parse", "--is-inside-work-tree"], cwd: "/") { _ in }

        #expect(recorder.events.first?.startedKind == .action)
    }

    @MainActor
    @Test func cancellingStreamTerminatesTheProcess() async throws {
        let task = Task { [runner] in
            try await runner.stream("sleep", ["10"], cwd: nil) { _ in }
        }
        try await waitUntil { [recorder] in recorder.events.isEmpty == false }

        let clock = ContinuousClock()
        let start = clock.now
        task.cancel()
        let status = try await task.value
        let elapsed = clock.now - start

        #expect(elapsed < .seconds(5))
        #expect(status == SIGTERM)
        #expect(recorder.events.last?.finishedError == "Cancelled")
    }

    @MainActor
    @Test func cancellingAnInterruptStreamLetsTheProcessFinish() async throws {
        let collector = LineCollector()
        let task = Task { [runner] in
            try await runner.stream("sh", ["-c", "trap 'exit 0' INT; echo ready; while :; do sleep 0.1; done"], cwd: nil, environment: [:], stop: .interrupt) { collector.add($0) }
        }
        try await waitUntil { collector.lines.contains("ready") }

        task.cancel()
        let status = try await task.value

        #expect(status == 0)
        #expect(recorder.events.last?.finishedError == nil)
    }
}

private final class LineCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var collected: [String] = []

    var lines: [String] {
        lock.withLock { collected }
    }

    func add(_ line: String) {
        lock.withLock { collected.append(line) }
    }
}

private func resolved(_ path: String) -> String {
    URL(fileURLWithPath: path).resolvingSymlinksInPath().path
}
