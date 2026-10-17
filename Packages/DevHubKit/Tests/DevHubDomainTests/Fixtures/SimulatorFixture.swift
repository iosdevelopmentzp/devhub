@testable import DevHubDomain

enum SimulatorFixture {
    static func booted(_ id: String) -> Simulator {
        Simulator(id: id, name: "iPhone \(id)", kind: .phone, state: .booted, isFavorite: false)
    }

    static func shutdown(_ id: String) -> Simulator {
        Simulator(id: id, name: "iPhone \(id)", kind: .phone, state: .shutdown, isFavorite: false)
    }
}
