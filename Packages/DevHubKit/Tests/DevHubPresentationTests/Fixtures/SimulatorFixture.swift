import DevHubDomain

enum SimulatorFixture {
    static let iPhone = Simulator(
        id: "8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13",
        name: "iPhone 16 Pro",
        kind: .phone,
        state: .booted,
        isFavorite: false
    )

    static let iPad = Simulator(
        id: "1B7E2C4D-6A8F-4B3C-9E21-5D7F9A1C3E24",
        name: "iPad Air",
        kind: .pad,
        state: .shutdown,
        isFavorite: false
    )

    static let device = Simulator(
        id: "00008110-000000000000001B",
        name: "Sam's iPhone",
        kind: .phone,
        state: .booted,
        isFavorite: false,
        isPhysical: true,
        runtime: "iOS 26.1"
    )

    static let offlineDevice = Simulator(
        id: "00008110-000000000000001A",
        name: "Alex's iPhone",
        kind: .phone,
        state: .shutdown,
        isFavorite: false,
        isPhysical: true,
        runtime: "iOS 18.6"
    )
}
