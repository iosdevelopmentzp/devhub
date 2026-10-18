import Foundation
import DevHubDomain
import DevHubUI

enum LogChipMapper {
    struct Option: Identifiable, Equatable {
        let id: Simulator.ID
        var title: String
    }

    static func models(streams: [LogStream], selectedID: Simulator.ID?, simulators: [Simulator]) -> [LogChipModel] {
        streams.map { stream in
            let isBooted = simulators.first { $0.id == stream.id }?.state == .booted
            return LogChipModel(
                id: stream.id,
                title: "\(stream.name) · \(isBooted ? "booted" : "off")",
                dotTint: dotTint(stream),
                isSelected: stream.id == selectedID
            )
        }
    }

    static func addOptions(available: [Simulator], runtime: (Simulator.ID) -> String?) -> [Option] {
        available.map { simulator in
            Option(id: simulator.id, title: [simulator.name, runtime(simulator.id)].compactMap { $0 }.joined(separator: " · "))
        }
    }

    private static func dotTint(_ stream: LogStream) -> Tint {
        if stream.error != nil { return .red }
        return stream.isRunning ? .green : .secondary
    }
}
