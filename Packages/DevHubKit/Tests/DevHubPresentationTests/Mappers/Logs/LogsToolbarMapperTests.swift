import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct LogsToolbarMapperTests {
    @Test func listsOnlyBootedSimulatorsWithRuntime() {
        let unknownRuntime = Simulator(id: "other", name: "iPhone SE", kind: .phone, state: .booted, isFavorite: false)

        let model = map(
            simulators: [SimulatorFixture.iPhone, SimulatorFixture.iPad, unknownRuntime],
            selected: nil,
            process: "ExampleApp",
            isPaused: false,
            pendingCount: 0,
            visibleLineCount: 0
        )

        #expect(model.simulators == [
            LogsToolbarModel.SimulatorOption(id: SimulatorFixture.iPhone.id, title: "iPhone 16 Pro · iOS 18.2"),
            LogsToolbarModel.SimulatorOption(id: "other", title: "iPhone SE · ")
        ])
    }

    @Test func canStartNeedsSimulatorAndProcess() {
        let id = SimulatorFixture.iPhone.id

        #expect(map(simulators: [], selected: id, process: "ExampleApp", isPaused: false, pendingCount: 0, visibleLineCount: 0).canStart)
        #expect(map(simulators: [], selected: nil, process: "ExampleApp", isPaused: false, pendingCount: 0, visibleLineCount: 0).canStart == false)
        #expect(map(simulators: [], selected: id, process: "  \n", isPaused: false, pendingCount: 0, visibleLineCount: 0).canStart == false)
    }

    @Test func pauseTitleShowsPendingLinesOnlyWhilePaused() {
        #expect(map(simulators: [], selected: nil, process: "", isPaused: false, pendingCount: 5, visibleLineCount: 0).pauseTitle == "Pause")
        #expect(map(simulators: [], selected: nil, process: "", isPaused: true, pendingCount: 0, visibleLineCount: 0).pauseTitle == "Pause")
        #expect(map(simulators: [], selected: nil, process: "", isPaused: true, pendingCount: 5, visibleLineCount: 0).pauseTitle == "Paused · 5 new")
    }

    @Test func copyNeedsVisibleLines() {
        let empty = map(simulators: [], selected: nil, process: "", isPaused: false, pendingCount: 0, visibleLineCount: 0)
        let three = map(simulators: [], selected: nil, process: "", isPaused: false, pendingCount: 0, visibleLineCount: 3)

        #expect(empty.canCopy == false)
        #expect(empty.copyLabel == "0 log lines")
        #expect(three.canCopy)
        #expect(three.copyLabel == "3 log lines")
    }

    @Test func transcriptJoinsLevelCategoryAndMessage() {
        let lines = [
            AppLogLine(id: 1, date: nil, level: .error, category: "Net", message: "Lost connection"),
            AppLogLine(id: 2, date: nil, level: .notice, category: "", message: "Started")
        ]

        #expect(LogsToolbarMapper.transcript(for: lines) == "Error\tNet\tLost connection\nDefault\t\tStarted")
        #expect(LogsToolbarMapper.transcript(for: []) == "")
    }

    private func map(
        simulators: [Simulator],
        selected: Simulator.ID?,
        process: String,
        isPaused: Bool,
        pendingCount: Int,
        visibleLineCount: Int
    ) -> LogsToolbarModel {
        LogsToolbarMapper.model(
            simulators: simulators,
            runtime: { $0 == SimulatorFixture.iPhone.id ? "iOS 18.2" : nil },
            selectedUDID: selected,
            process: process,
            isPaused: isPaused,
            pendingCount: pendingCount,
            visibleLineCount: visibleLineCount
        )
    }
}
