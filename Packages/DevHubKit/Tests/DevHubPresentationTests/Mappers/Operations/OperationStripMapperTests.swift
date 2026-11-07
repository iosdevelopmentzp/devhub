import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct OperationStripMapperTests {
    private func card(_ title: String, isRunning: Bool = false, steps: Int = 0, message: String? = nil, liveLine: String? = nil, fraction: Double? = nil, hasFullOutput: Bool = false, hidesSoon: Bool = false) -> OperationCardModel {
        OperationCardModel(
            id: UUID(),
            title: title,
            icon: isRunning ? "circle.dotted" : "checkmark.circle.fill",
            tint: isRunning ? .blue : .green,
            isRunning: isRunning,
            startedAt: Date(),
            detail: isRunning ? "Step 2 of 3" : "1.2 s",
            fraction: fraction,
            steps: (0..<steps).map { OperationCardModel.Step(id: UUID(), command: "git step \($0)", icon: "checkmark.circle.fill", tint: .green, isRunning: false, duration: nil) },
            hiddenStepCount: 0,
            liveLine: liveLine,
            message: message,
            failedStep: nil,
            digest: [],
            fullOutput: nil,
            hasFullOutput: hasFullOutput,
            isOutputOpen: false,
            canRetry: message != nil,
            canStop: isRunning,
            canDismiss: isRunning == false,
            hidesSoon: hidesSoon,
            errorText: nil
        )
    }

    @Test func aFailureShowsItsMessageAndOpensTheCard() {
        let failed = OperationCardModel.preview

        let row = OperationStripMapper.row(for: failed, isExpanded: false)

        #expect(row.title == failed.title)
        #expect(row.icon == "xmark.octagon.fill")
        #expect(row.tint == .red)
        #expect(row.summary == "The remote has commits that you do not have.")
        #expect(row.detail == "1.2 s")
        #expect(row.canRetry)
        #expect(row.canDismiss)
        #expect(row.canStop == false)
        #expect(row.canExpand)
        #expect(row.isExpanded == false)
        #expect(row.expandHint == "Show the steps and the lines that explain the failure")
        #expect(OperationStripMapper.row(for: failed, isExpanded: true).expandHint == "Hide the card of this operation")
    }

    @Test func aRunningOperationShowsItsLastLineAndProgress() {
        let running = card("Regenerate Project", isRunning: true, steps: 1, liveLine: "./scripts/regenerate.sh", fraction: 0.6)

        let row = OperationStripMapper.row(for: running, isExpanded: false)

        #expect(row.isRunning)
        #expect(row.summary == "./scripts/regenerate.sh")
        #expect(row.fraction == 0.6)
        #expect(row.detail == "Step 2 of 3")
        #expect(row.canStop)
        #expect(row.canDismiss == false)
        #expect(row.canExpand)
        #expect(row.expandHint == "Show the steps of this operation")
    }

    @Test func aSuccessWithoutStepsCannotExpandAndHidesSoon() {
        let row = OperationStripMapper.row(for: card("Fetch", hidesSoon: true), isExpanded: false)

        #expect(row.canExpand == false)
        #expect(row.hidesSoon)
        #expect(row.summary == nil)
        #expect(OperationStripMapper.row(for: card("Fetch", hasFullOutput: true), isExpanded: false).canExpand)
    }

    @Test func atMostThreeRowsShowAndTheRestAreCounted() {
        let cards = (1...5).map { card("Op \($0)") }

        let model = OperationStripMapper.model(for: cards, expandedID: cards[1].id)

        #expect(model.rows.map(\.title) == ["Op 1", "Op 2", "Op 3"])
        #expect(model.rows.map(\.isExpanded) == [false, true, false])
        #expect(model.moreText == "2 more in the footer list")
        #expect(OperationStripMapper.model(for: Array(cards.prefix(3)), expandedID: nil).moreText == nil)
        #expect(OperationStripMapper.model(for: [], expandedID: nil).rows.isEmpty)
    }
}
