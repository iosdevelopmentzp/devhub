import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct OperationCardMapperTests {
    private let operationID = UUID()
    private let startedAt = Date(timeIntervalSince1970: 1_000)

    @Test func aRunningOperationShowsItsStepsAndTheLastLine() {
        let entries = [
            finished("git fetch origin", lines: ["From github.com:example/app"]),
            running("git push origin feature/ABC-123", lines: ["Counting objects: 3", "Writing objects: 100%", ""]),
        ]

        let model = OperationCardMapper.model(for: record(.running, progress: "Uploading", fraction: 1.4), entries: entries)

        #expect(model.title == "Push")
        #expect(model.tint == .blue)
        #expect(model.isRunning)
        #expect(model.detail == "Uploading")
        #expect(model.fraction == 1)
        #expect(model.steps.map(\.command) == ["git fetch origin", "git push origin feature/ABC-123"])
        #expect(model.steps.map(\.isRunning) == [false, true])
        #expect(model.steps.first?.icon == "checkmark.circle.fill")
        #expect(model.liveLine == "Writing objects: 100%")
        #expect(model.canDismiss == false)
        #expect(model.canRetry == false)
        #expect(model.hasFullOutput == false)
        #expect(model.errorText == nil)
    }

    @Test func aFailedOperationNamesTheStepAndTheTellingLines() {
        let entries = [
            failed("git push origin feature/ABC-123", exitCode: 1, lines: [
                "To github.com:example/app.git",
                " ! [rejected] feature/ABC-123 -> feature/ABC-123 (fetch first)",
                "error: failed to push some refs",
            ]),
        ]

        let model = OperationCardMapper.model(for: record(.failed("error: failed to push some refs")), entries: entries)

        #expect(model.title == "Push failed")
        #expect(model.icon == "xmark.octagon.fill")
        #expect(model.tint == .red)
        #expect(model.message == "error: failed to push some refs")
        #expect(model.failedStep == "git push origin feature/ABC-123 · exit 1")
        #expect(model.digest == ["! [rejected] feature/ABC-123 -> feature/ABC-123 (fetch first)"])
        #expect(model.steps.first?.tint == .red)
        #expect(model.canRetry)
        #expect(model.canDismiss)
        #expect(model.hasFullOutput)
        #expect(model.fullOutput == nil)
        #expect(model.hidesSoon == false)
        #expect(model.errorText == """
        Push failed
        error: failed to push some refs
        $ git push origin feature/ABC-123 · exit 1
        ! [rejected] feature/ABC-123 -> feature/ABC-123 (fetch first)
        error: failed to push some refs
        """)
    }

    @Test func theFullOutputShowsWhenOpen() {
        var opened = record(.failed("Exited with code 2."))
        opened.isOutputOpen = true
        let entries = [failed("./scripts/run.sh", exitCode: 2, lines: ["one", "two"])]

        let model = OperationCardMapper.model(for: opened, entries: entries)

        #expect(model.isOutputOpen)
        #expect(model.fullOutput == "one\ntwo")
        #expect(model.digest == ["one", "two"])
    }

    @Test func readCommandsShowOnlyWhenTheyFail() {
        let entries = [
            entry("git status --porcelain", kind: .read, exitCode: 0, error: nil, lines: [], isFinished: true),
            entry("git rev-parse HEAD", kind: .read, exitCode: 128, error: nil, lines: ["fatal: bad revision"], isFinished: true),
        ]

        let model = OperationCardMapper.model(for: record(.failed("bad revision")), entries: entries)

        #expect(model.steps.map(\.command) == ["git rev-parse HEAD"])
        #expect(model.digest == ["fatal: bad revision"])
    }

    @Test func entriesOfOtherOperationsAreLeftOut() {
        var other = finished("git fetch", lines: [])
        other.operationID = UUID()
        let untagged = CommandLog.Entry(
            id: UUID(),
            command: "git status",
            cwd: nil,
            kind: .action,
            operationID: nil,
            startedAt: startedAt,
            finishedAt: startedAt,
            exitCode: 0,
            error: nil,
            lines: [],
            droppedLines: 0
        )

        let model = OperationCardMapper.model(for: record(.succeeded), entries: [other, untagged])

        #expect(model.steps.isEmpty)
    }

    @Test func aSuccessHidesSoonAndOffersNothingElse() {
        let model = OperationCardMapper.model(for: record(.succeeded), entries: [finished("git push", lines: ["done"])])

        #expect(model.title == "Push")
        #expect(model.icon == "checkmark.circle.fill")
        #expect(model.tint == .green)
        #expect(model.hidesSoon)
        #expect(model.canRetry == false)
        #expect(model.errorText == nil)
        #expect(model.detail?.isEmpty == false)
    }

    @Test func aSuccessWithAFailedStepWarns() {
        let entries = [
            finished("git commit -m Fix", lines: []),
            failed("git push", exitCode: 1, lines: ["error: failed to push some refs"]),
        ]

        let model = OperationCardMapper.model(for: record(.succeeded), entries: entries)

        #expect(model.title == "Push · a step failed")
        #expect(model.tint == .orange)
        #expect(model.hidesSoon == false)
        #expect(model.message == nil)
        #expect(model.failedStep == "git push · exit 1")
        #expect(model.digest == ["error: failed to push some refs"])
        #expect(model.canRetry)
    }

    @Test func aStoppedOperationIsGrey() {
        let entries = [entry("./scripts/long.sh", kind: .action, exitCode: nil, error: "Cancelled", lines: [], isFinished: true)]

        let model = OperationCardMapper.model(for: record(.cancelled), entries: entries)

        #expect(model.title == "Push stopped")
        #expect(model.tint == .secondary)
        #expect(model.failedStep == "./scripts/long.sh · Cancelled")
    }

    @Test func onlyTheLastStepsAreListed() {
        let entries = (1...8).map { finished("step \($0)", lines: []) }

        let model = OperationCardMapper.model(for: record(.succeeded), entries: entries)

        #expect(model.steps.map(\.command) == ["step 3", "step 4", "step 5", "step 6", "step 7", "step 8"])
        #expect(model.hiddenStepCount == 2)
    }

    @Test func stopIsOfferedOnlyWhileRunning() {
        var stoppable = record(.running, progress: nil, fraction: nil)
        stoppable.canStop = true

        #expect(OperationCardMapper.model(for: stoppable, entries: []).canStop)
        stoppable.status = .succeeded
        #expect(OperationCardMapper.model(for: stoppable, entries: []).canStop == false)
    }

    private func record(_ status: OperationRecord.Status) -> OperationRecord {
        record(status, progress: nil, fraction: nil)
    }

    private func record(_ status: OperationRecord.Status, progress: String?, fraction: Double?) -> OperationRecord {
        OperationRecord(
            id: operationID,
            title: "Push",
            origin: .git,
            startedAt: startedAt,
            finishedAt: status == .running ? nil : startedAt.addingTimeInterval(1.5),
            status: status,
            progressText: progress,
            fraction: fraction,
            canRetry: true,
            canStop: false,
            isDismissed: false,
            isSeen: false,
            isOutputOpen: false
        )
    }

    private func finished(_ command: String, lines: [String]) -> CommandLog.Entry {
        entry(command, kind: .action, exitCode: 0, error: nil, lines: lines, isFinished: true)
    }

    private func running(_ command: String, lines: [String]) -> CommandLog.Entry {
        entry(command, kind: .action, exitCode: nil, error: nil, lines: lines, isFinished: false)
    }

    private func failed(_ command: String, exitCode: Int32, lines: [String]) -> CommandLog.Entry {
        entry(command, kind: .action, exitCode: exitCode, error: nil, lines: lines, isFinished: true)
    }

    private func entry(_ command: String, kind: CommandKind, exitCode: Int32?, error: String?, lines: [String], isFinished: Bool) -> CommandLog.Entry {
        CommandLog.Entry(
            id: UUID(),
            command: command,
            cwd: "/repo",
            kind: kind,
            operationID: operationID,
            startedAt: startedAt,
            finishedAt: isFinished ? startedAt.addingTimeInterval(0.5) : nil,
            exitCode: exitCode,
            error: error,
            lines: lines,
            droppedLines: 0
        )
    }
}
