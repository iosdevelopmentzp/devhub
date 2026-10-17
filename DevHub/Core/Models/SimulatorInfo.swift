import Foundation

nonisolated struct SimulatorInfo: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable {
        case booted
        case shutdown
    }

    let id: String
    var name: String
    var runtime: String
    var state: State
    var appCount: Int
    var isFavorite: Bool

    var isBooted: Bool { state == .booted }

    var isPad: Bool { name.contains("iPad") }

    var symbol: String { isPad ? "ipad" : "iphone" }

    var longTitle: String { "\(name) · \(runtime)" }

    var appCountText: String {
        appCount == 1 ? "1 app installed" : "\(appCount) apps installed"
    }
}

nonisolated struct TargetSimulator: Hashable, Sendable {
    let id: String
    let name: String
    let isBooted: Bool
}

nonisolated struct SimulatorSection: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let isFavorites: Bool
    let simulators: [SimulatorInfo]

    var countText: String {
        simulators.count == 1 ? "1 device" : "\(simulators.count) devices"
    }

    static func build(from simulators: [SimulatorInfo]) -> [SimulatorSection] {
        var sections: [SimulatorSection] = []
        let favorites = simulators.filter(\.isFavorite)
        if favorites.isEmpty == false {
            sections.append(SimulatorSection(id: "favorites", title: "Favorites", isFavorites: true, simulators: favorites))
        }
        var order: [String] = []
        for simulator in simulators where order.contains(simulator.runtime) == false {
            order.append(simulator.runtime)
        }
        for runtime in order {
            sections.append(SimulatorSection(id: runtime, title: runtime, isFavorites: false, simulators: simulators.filter { $0.runtime == runtime }))
        }
        return sections
    }
}

nonisolated enum SimulatorConfirmation: Hashable, Sendable {
    case erase(String)
    case removeAll
}

nonisolated struct RemovalProgress: Hashable, Sendable {
    var done: Int
    var total: Int
    var name: String
}
