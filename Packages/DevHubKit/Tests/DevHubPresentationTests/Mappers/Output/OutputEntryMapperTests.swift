import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct OutputEntryMapperTests {
    let now = CommandLogEntryFixture.startedAt.addingTimeInterval(0.25)

    @Test func visibleEntriesHideReadsUnlessAsked() {
        let entries = [CommandLogEntryFixture.finished, CommandLogEntryFixture.read]

        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: false, failedOnly: false, query: "").map(\.id) == [CommandLogEntryFixture.finished.id])
        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: false, query: "").map(\.id) == entries.map(\.id))
    }

    @Test func visibleEntriesMatchCommandOutputOrErrorIgnoringCase() {
        var failed = CommandLogEntryFixture.read
        failed.kind = .action
        failed.error = "Permission DENIED"
        let entries = [CommandLogEntryFixture.finished, failed]

        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: false, query: " FETCH ").map(\.id) == [CommandLogEntryFixture.finished.id])
        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: false, query: "new branch").map(\.id) == [CommandLogEntryFixture.finished.id])
        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: false, query: "denied").map(\.id) == [failed.id])
        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: false, query: "nothing").isEmpty)
    }

    @Test func failedOnlyKeepsTheFailuresOfEveryKind() {
        var failedAction = CommandLogEntryFixture.finished
        failedAction.exitCode = 1
        var failedRead = CommandLogEntryFixture.read
        failedRead.error = "boom"
        var running = CommandLogEntryFixture.finished
        running.finishedAt = nil
        running.exitCode = nil
        let entries = [CommandLogEntryFixture.finished, failedAction, failedRead, running]

        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: false, failedOnly: true, query: "").map(\.id) == [failedAction.id])
        #expect(OutputEntryMapper.visibleEntries(entries, showsReads: true, failedOnly: true, query: "").map(\.id) == [failedAction.id, failedRead.id])
    }

    @Test func finishedSuccessfulAction() {
        let entry = CommandLogEntryFixture.finished

        let model = OutputEntryMapper.model(for: entry, isExpanded: false, now: now)

        #expect(model.id == entry.id)
        #expect(model.command == entry.command)
        #expect(model.commandLine == "$ git -C ~/Projects/ExampleApp fetch --prune")
        #expect(model.folder == "/Users/dev/Projects/ExampleApp".abbreviatingHome)
        #expect(model.folderPath == "/Users/dev/Projects/ExampleApp")
        #expect(model.startedText.isEmpty == false)
        #expect(model.fullOutput == entry.output)
        #expect(model.durationText == "2.5 s")
        #expect(model.isRunning == false)
        #expect(model.statusIcon == "checkmark.circle.fill")
        #expect(model.statusTint == .green)
        #expect(model.statusHint == nil)
        #expect(model.isExpanded == false)
        #expect(model.canExpand == false)
        #expect(model.expandIcon == "chevron.down")
        #expect(model.expandHint == "Show all 2 lines")
        #expect(model.output == "From gitlab.example.com:top/live\n * [new branch] feature/gifts")
        #expect(model.outputTint == nil)
        #expect(model.error == nil)
    }

    @Test func runningEntryUsesNow() {
        var entry = CommandLogEntryFixture.finished
        entry.finishedAt = nil
        entry.exitCode = nil

        let model = OutputEntryMapper.model(for: entry, isExpanded: false, now: now)

        #expect(model.isRunning)
        #expect(model.durationText == "250 ms")
    }

    @Test func readEntryIsSecondaryWithoutOutput() {
        let model = OutputEntryMapper.model(for: CommandLogEntryFixture.read, isExpanded: false, now: now)

        #expect(model.statusTint == .secondary)
        #expect(model.folder == nil)
        #expect(model.folderPath == nil)
        #expect(model.output == nil)
        #expect(model.fullOutput == nil)
    }

    @Test func failureByExitCode() {
        var entry = CommandLogEntryFixture.finished
        entry.exitCode = 128

        let model = OutputEntryMapper.model(for: entry, isExpanded: false, now: now)

        #expect(model.statusIcon == "xmark.circle.fill")
        #expect(model.statusTint == .red)
        #expect(model.statusHint == "Exit code 128")
        #expect(model.outputTint == .red)
    }

    @Test func failureByErrorOnly() {
        var entry = CommandLogEntryFixture.read
        entry.exitCode = nil
        entry.error = "launch failed"

        let model = OutputEntryMapper.model(for: entry, isExpanded: false, now: now)

        #expect(model.statusTint == .red)
        #expect(model.statusHint == "Failed")
        #expect(model.error == "launch failed")
    }

    @Test func collapsedLongOutputShowsTheLastEightLines() {
        var entry = CommandLogEntryFixture.finished
        entry.lines = CommandLogEntryFixture.lines(10)

        let model = OutputEntryMapper.model(for: entry, isExpanded: false, now: now)

        #expect(model.canExpand)
        #expect(model.expandIcon == "chevron.down")
        #expect(model.expandHint == "Show all 10 lines")
        #expect(model.output == "… 2 more lines above\n" + (2..<10).map { "line \($0)" }.joined(separator: "\n"))
    }

    @Test func expandedOutputShowsEveryLineAndDroppedNote() {
        var entry = CommandLogEntryFixture.finished
        entry.lines = CommandLogEntryFixture.lines(10)
        entry.droppedLines = 5

        let model = OutputEntryMapper.model(for: entry, isExpanded: true, now: now)

        #expect(model.isExpanded)
        #expect(model.expandIcon == "chevron.up")
        #expect(model.expandHint == "Show less")
        #expect(model.output == "… 5 earlier lines dropped\n" + entry.output)
    }

    @Test func shortOutputWithDroppedLinesShowsTheDroppedNote() {
        var entry = CommandLogEntryFixture.finished
        entry.lines = ["tail"]
        entry.droppedLines = 3

        #expect(OutputEntryMapper.model(for: entry, isExpanded: false, now: now).output == "… 3 earlier lines dropped\ntail")
    }

    @Test func transcriptOfOneEntry() {
        var entry = CommandLogEntryFixture.finished
        entry.exitCode = 1
        entry.error = "rejected"

        #expect(OutputEntryMapper.transcript(for: entry) == """
        # in /Users/dev/Projects/ExampleApp
        $ git -C ~/Projects/ExampleApp fetch --prune
        From gitlab.example.com:top/live
         * [new branch] feature/gifts
        # exit code 1
        # rejected
        """)
        #expect(OutputEntryMapper.transcript(for: CommandLogEntryFixture.read) == "$ git status --porcelain")
    }

    @Test func transcriptOfManyEntriesIsSeparatedByABlankLine() {
        let entries = [CommandLogEntryFixture.read, CommandLogEntryFixture.read]

        #expect(OutputEntryMapper.transcript(for: entries) == "$ git status --porcelain\n\n$ git status --porcelain")
        #expect(OutputEntryMapper.transcript(for: [CommandLog.Entry]()) == "")
    }
}
