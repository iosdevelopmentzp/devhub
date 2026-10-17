import Foundation
import DevHubDomain

extension MockData {
    package static let simulatorGroups: [SimulatorGroup] = [
        SimulatorGroup(
            runtime: "iOS 26.0",
            simulators: [
                Simulator(id: "sim-17pro", name: "iPhone 17 Pro", kind: .phone, state: .booted, isFavorite: true),
                Simulator(id: "sim-17", name: "iPhone 17", kind: .phone, state: .shutdown, isFavorite: false),
                Simulator(id: "sim-air", name: "iPhone Air", kind: .phone, state: .shutdown, isFavorite: false),
                Simulator(id: "sim-ipad13", name: "iPad Pro 13-inch (M5)", kind: .pad, state: .shutdown, isFavorite: false)
            ]
        ),
        SimulatorGroup(
            runtime: "iOS 18.6",
            simulators: [
                Simulator(id: "sim-16", name: "iPhone 16", kind: .phone, state: .shutdown, isFavorite: true),
                Simulator(id: "sim-se", name: "iPhone SE (3rd generation)", kind: .phone, state: .shutdown, isFavorite: false)
            ]
        ),
        SimulatorGroup(
            runtime: "iOS 16.4",
            simulators: [
                Simulator(id: "sim-14", name: "iPhone 14", kind: .phone, state: .shutdown, isFavorite: false)
            ]
        )
    ]
}
