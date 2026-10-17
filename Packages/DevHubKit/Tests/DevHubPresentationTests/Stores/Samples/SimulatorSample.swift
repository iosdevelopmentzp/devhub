import DevHubDomain

enum SimulatorSample {
    static let booted = Simulator(id: "sim-booted", name: "iPhone 17", kind: .phone, state: .booted, isFavorite: false)
    static let shutdown = Simulator(id: "sim-off", name: "iPhone 16e", kind: .phone, state: .shutdown, isFavorite: false)
    static let pad = Simulator(id: "sim-pad", name: "iPad Air", kind: .pad, state: .shutdown, isFavorite: false)

    static let groups = [
        SimulatorGroup(runtime: "iOS 26.0", simulators: [booted, shutdown]),
        SimulatorGroup(runtime: "iOS 18.6", simulators: [pad]),
    ]

    static let shutdownOnly = [SimulatorGroup(runtime: "iOS 26.0", simulators: [shutdown])]
}
