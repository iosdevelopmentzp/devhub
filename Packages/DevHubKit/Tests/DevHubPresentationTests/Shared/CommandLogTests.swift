import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CommandLogTests {
    let log = CommandLog()

    @Test func startedAddsRunningEntry() throws {
        let id = UUID()

        log.handle(CommandEvent(id: id, payload: .started(command: "git fetch", cwd: "/tmp/repo", kind: .action, operationID: nil)))

        let entry = try #require(log.entries.first)
        #expect(log.entries.count == 1)
        #expect(entry.id == id)
        #expect(entry.command == "git fetch")
        #expect(entry.cwd == "/tmp/repo")
        #expect(entry.kind == .action)
        #expect(entry.lines.isEmpty)
        #expect(entry.droppedLines == 0)
        #expect(entry.isRunning)
        #expect(entry.isFailure == false)
    }

    @Test func startedKeepsTheOperation() {
        let operationID = UUID()

        log.handle(CommandEvent(id: UUID(), payload: .started(command: "git push", cwd: nil, kind: .action, operationID: operationID)))

        #expect(log.entries.first?.operationID == operationID)
    }

    @Test func outputAppendsLinesToTheMatchingEntry() throws {
        let id = UUID()
        let other = UUID()
        start(id, kind: .action)
        start(other, kind: .action)

        log.handle(CommandEvent(id: id, payload: .output(["one", "two"])))
        log.handle(CommandEvent(id: id, payload: .output(["three"])))

        let entry = try #require(log.entries.first { $0.id == id })
        #expect(entry.lines == ["one", "two", "three"])
        #expect(entry.output == "one\ntwo\nthree")
        #expect(log.entries.first { $0.id == other }?.lines == [])
    }

    @Test func finishedRecordsExitCodeAndError() throws {
        let id = UUID()
        start(id, kind: .action)

        log.handle(CommandEvent(id: id, payload: .finished(exitCode: 0, error: nil)))

        let entry = try #require(log.entries.first)
        #expect(entry.isRunning == false)
        #expect(entry.finishedAt != nil)
        #expect(entry.exitCode == 0)
        #expect(entry.isFailure == false)
    }

    @Test func nonZeroExitCodeOrErrorIsFailure() {
        let exitID = UUID()
        let errorID = UUID()
        start(exitID, kind: .action)
        start(errorID, kind: .action)

        log.handle(CommandEvent(id: exitID, payload: .finished(exitCode: 128, error: nil)))
        log.handle(CommandEvent(id: errorID, payload: .finished(exitCode: nil, error: "launch failed")))

        #expect(log.entries.map(\.isFailure) == [true, true])
        #expect(log.entries[1].error == "launch failed")
    }

    @Test func eventsForUnknownIDsAreIgnored() {
        log.handle(CommandEvent(id: UUID(), payload: .output(["lost"])))
        log.handle(CommandEvent(id: UUID(), payload: .finished(exitCode: 1, error: nil)))

        #expect(log.entries.isEmpty)
    }

    @Test func secretKindHidesOutput() throws {
        let id = UUID()
        start(id, kind: .secret)

        log.handle(CommandEvent(id: id, payload: .output(["token=abc"])))

        let entry = try #require(log.entries.first)
        #expect(entry.lines == [CommandLog.hiddenOutput])
        #expect(CommandLog.hiddenOutput == "Output hidden: it contains credentials.")
    }

    @Test func appLogKindPointsToTheLogsTab() throws {
        let id = UUID()
        start(id, kind: .appLog)

        log.handle(CommandEvent(id: id, payload: .output(["app line"])))

        let entry = try #require(log.entries.first)
        #expect(entry.lines == [CommandLog.appLogOutput])
        #expect(CommandLog.appLogOutput == "App log lines are shown in the Logs tab only.")
    }

    @Test func readKindKeepsOutput() {
        let id = UUID()
        start(id, kind: .read)

        log.handle(CommandEvent(id: id, payload: .output(["M file.swift"])))

        #expect(log.entries.first?.lines == ["M file.swift"])
    }

    @Test func linesAreCappedAndDroppedLinesCounted() throws {
        let id = UUID()
        start(id, kind: .action)

        log.handle(CommandEvent(id: id, payload: .output(CommandLogEntryFixture.lines(3_998))))
        log.handle(CommandEvent(id: id, payload: .output(["a", "b", "c", "d", "e"])))

        let entry = try #require(log.entries.first)
        #expect(entry.lines.count == 4_000)
        #expect(entry.droppedLines == 3)
        #expect(entry.lines.first == "line 3")
        #expect(entry.lines.last == "e")
    }

    @Test func entriesAreCappedAtThreeHundred() {
        let ids = (0..<301).map { _ in UUID() }

        for id in ids {
            start(id, kind: .action)
        }

        #expect(log.entries.count == 300)
        #expect(log.entries.first?.id == ids[1])
        #expect(log.entries.last?.id == ids[300])
    }

    @Test func clearKeepsRunningEntries() {
        let running = UUID()
        let finished = UUID()
        start(running, kind: .action)
        start(finished, kind: .action)
        log.handle(CommandEvent(id: finished, payload: .finished(exitCode: 0, error: nil)))

        log.clear()

        #expect(log.entries.map(\.id) == [running])
    }

    private func start(_ id: UUID, kind: CommandKind) {
        log.handle(CommandEvent(id: id, payload: .started(command: "cmd", cwd: nil, kind: kind, operationID: nil)))
    }
}
