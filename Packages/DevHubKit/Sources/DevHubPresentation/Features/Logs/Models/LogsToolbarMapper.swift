import Foundation
import DevHubDomain
import DevHubUI

enum LogsToolbarMapper {

    static func model(
        simulators: [Simulator],
        runtime: (Simulator.ID) -> String?,
        selectedUDID: Simulator.ID?,
        process: String,
        isPaused: Bool,
        pendingCount: Int,
        visibleLineCount: Int
    ) -> LogsToolbarModel {
        LogsToolbarModel(
            simulators: simulators
                .filter { $0.state == .booted }
                .map { LogsToolbarModel.SimulatorOption(id: $0.id, title: "\($0.name) · \(runtime($0.id) ?? "")") },
            canStart: selectedUDID != nil && process.trimmed.isEmpty == false,
            pauseTitle: isPaused && pendingCount > 0 ? "Paused · \(pendingCount) new" : "Pause",
            canCopy: visibleLineCount > 0,
            copyLabel: CountText.invariant(visibleLineCount, "log lines")
        )
    }

    static func transcript(for lines: [AppLogLine]) -> String {
        lines
            .map { "\(LogLineRowMapper.title(for: $0.level))\t\($0.category)\t\($0.message)" }
            .joined(separator: "\n")
    }
}
