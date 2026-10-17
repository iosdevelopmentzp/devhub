import Foundation

nonisolated struct ParsedSimulator: Hashable, Sendable {
    var id: String
    var name: String
    var platform: String
    var runtimeVersion: [Int]
    var isBooted: Bool
    var isPad: Bool
    var isPhone: Bool

    var runtimeName: String {
        let version = runtimeVersion.map(String.init).joined(separator: ".")
        return version.isEmpty ? platform : "\(platform) \(version)"
    }
}

nonisolated enum SimulatorListParser {
    static func parse(_ data: Data) -> [ParsedSimulator]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let runtimes = root["devices"] as? [String: [[String: Any]]] else { return nil }
        let parsed = runtimes.flatMap { runtimeID, devices in
            let runtime = parseRuntime(runtimeID)
            return devices.compactMap { device in simulator(from: device, runtime: runtime) }
        }
        return parsed.sorted(by: isOrderedBefore)
    }

    static func parseRuntime(_ identifier: String) -> (platform: String, version: [Int]) {
        let tail = identifier.components(separatedBy: "SimRuntime.").last ?? identifier
        let parts = tail.split(separator: "-").map(String.init)
        guard let platform = parts.first else { return (tail, []) }
        return (platform, parts.dropFirst().compactMap { Int($0) })
    }

    private static func simulator(from device: [String: Any], runtime: (platform: String, version: [Int])) -> ParsedSimulator? {
        guard let id = device["udid"] as? String, let name = device["name"] as? String else { return nil }
        guard device["isAvailable"] as? Bool ?? true else { return nil }
        let type = device["deviceTypeIdentifier"] as? String ?? name
        return ParsedSimulator(
            id: id,
            name: name,
            platform: runtime.platform,
            runtimeVersion: runtime.version,
            isBooted: device["state"] as? String == "Booted",
            isPad: type.contains("iPad"),
            isPhone: type.contains("iPhone")
        )
    }

    private static func isOrderedBefore(_ lhs: ParsedSimulator, _ rhs: ParsedSimulator) -> Bool {
        if lhs.platform != rhs.platform {
            return lhs.platform < rhs.platform
        }
        if lhs.runtimeVersion != rhs.runtimeVersion {
            return lhs.runtimeVersion.lexicographicallyPrecedes(rhs.runtimeVersion) == false
        }
        if lhs.rank != rhs.rank {
            return lhs.rank < rhs.rank
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}

private nonisolated extension ParsedSimulator {
    var rank: Int {
        if isPhone { return 0 }
        return isPad ? 1 : 2
    }
}
