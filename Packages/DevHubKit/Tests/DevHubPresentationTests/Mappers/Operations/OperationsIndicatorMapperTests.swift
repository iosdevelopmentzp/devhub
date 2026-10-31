import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct OperationsIndicatorMapperTests {
    @Test func nothingShowsWithoutOperations() {
        #expect(OperationsIndicatorMapper.model(for: []) == nil)
    }

    @Test func oneRunningOperationShowsItsTitleAndProgress() {
        var push = record("Push", .running)
        #expect(OperationsIndicatorMapper.model(for: [push])?.text == "Push")

        push.progressText = "Step 2"
        let model = OperationsIndicatorMapper.model(for: [push])

        #expect(model?.text == "Push: Step 2")
        #expect(model?.isRunning == true)
        #expect(model?.tint == .blue)
    }

    @Test func severalRunningOperationsShowACount() {
        let model = OperationsIndicatorMapper.model(for: [record("Push", .running), record("Script", .running), record("Fetch", .failed("offline"))])

        #expect(model?.text == "2 running")
        #expect(model?.isRunning == true)
    }

    @Test func unseenFailuresShowInRed() {
        var seen = record("Fetch", .failed("offline"))
        seen.isSeen = true
        let model = OperationsIndicatorMapper.model(for: [record("Push", .failed("rejected")), seen, record("Pull", .succeeded)])

        #expect(model?.text == "1 failed")
        #expect(model?.icon == "xmark.octagon.fill")
        #expect(model?.tint == .red)
        #expect(model?.textTint == .red)
        #expect(model?.isRunning == false)
    }

    @Test func finishedOperationsLeaveAQuietButton() {
        let model = OperationsIndicatorMapper.model(for: [record("Pull", .succeeded)])

        #expect(model?.text == nil)
        #expect(model?.icon == "list.bullet.rectangle")
        #expect(model?.tint == .secondary)
        #expect(model?.hint == OperationsIndicatorMapper.hint)
    }

    private func record(_ title: String, _ status: OperationRecord.Status) -> OperationRecord {
        OperationRecord(
            id: UUID(),
            title: title,
            origin: .git,
            startedAt: Date(timeIntervalSince1970: 1_000),
            finishedAt: status == .running ? nil : Date(timeIntervalSince1970: 1_002),
            status: status,
            progressText: nil,
            fraction: nil,
            canRetry: false,
            canStop: false,
            isDismissed: false,
            isSeen: false,
            isOutputOpen: false
        )
    }
}
