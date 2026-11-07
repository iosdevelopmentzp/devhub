@testable import DevHubDomain

enum SimulatorFixture {
    static func booted(_ id: String) -> Simulator {
        Simulator(id: id, name: "iPhone \(id)", kind: .phone, state: .booted, isFavorite: false)
    }

    static func shutdown(_ id: String) -> Simulator {
        Simulator(id: id, name: "iPhone \(id)", kind: .phone, state: .shutdown, isFavorite: false)
    }

    static func device(_ id: String, connected: Bool = true) -> Simulator {
        Simulator(id: id, name: "Sam's iPhone", kind: .phone, state: connected ? .booted : .shutdown, isFavorite: false, isPhysical: true, runtime: "iOS 26.1")
    }
}
