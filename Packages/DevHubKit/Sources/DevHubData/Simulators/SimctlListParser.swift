import Foundation
import DevHubDomain

enum SimctlListParser {
    private struct Device: Decodable {
        let udid: String
        let name: String
        let state: String
        let deviceTypeIdentifier: String?
        let isAvailable: Bool?
    }

    private struct DeviceList: Decodable {
        let devices: [String: [Device]]
    }

    private struct Runtime {
        let identifier: String
        let name: String
        let version: [Int]
    }

    static func parse(_ data: Data) throws -> [SimulatorGroup] {
        let list: DeviceList
        do {
            list = try JSONDecoder().decode(DeviceList.self, from: data)
        } catch {
            throw SimulatorError.malformedList
        }

        let groups = list.devices.compactMap { identifier, devices -> (runtime: Runtime, simulators: [Simulator])? in
            guard let runtime = runtime(from: identifier) else { return nil }
            let simulators = devices
                .filter { $0.isAvailable ?? true }
                .map { simulator(from: $0) }
                .sorted { lhs, rhs in
                    if lhs.kind != rhs.kind { return lhs.kind == .phone }
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
            guard simulators.isEmpty == false else { return nil }
            return (runtime, simulators)
        }
        return groups
            .sorted { $0.runtime.version.lexicographicallyPrecedes($1.runtime.version) == false }
            .map { SimulatorGroup(runtime: $0.runtime.name, simulators: $0.simulators) }
    }

    private static func runtime(from identifier: String) -> Runtime? {
        let raw = identifier.components(separatedBy: ".").last ?? identifier
        let parts = raw.components(separatedBy: CharacterSet(charactersIn: "- "))
        guard let platform = parts.first, platform == "iOS" else { return nil }
        let version = parts.dropFirst().compactMap { Int($0) }
        return Runtime(
            identifier: identifier,
            name: "\(platform) \(version.map(String.init).joined(separator: "."))",
            version: version
        )
    }

    private static func simulator(from device: Device) -> Simulator {
        Simulator(
            id: device.udid,
            name: device.name.trimmed,
            kind: (device.deviceTypeIdentifier ?? device.name).contains("iPad") ? .pad : .phone,
            state: state(from: device.state),
            isFavorite: false
        )
    }

    private static func state(from raw: String) -> Simulator.State {
        switch raw {
        case "Booted": .booted
        case "Booting": .booting
        case "Shutting Down": .shuttingDown
        default: .shutdown
        }
    }
}
