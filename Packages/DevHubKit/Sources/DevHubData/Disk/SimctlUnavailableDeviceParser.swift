import Foundation
import DevHubDomain

enum SimctlUnavailableDeviceParser {
    private struct Device: Decodable {
        let udid: String
        let dataPath: String?
        let dataPathSize: Int64?
        let isAvailable: Bool?
    }

    private struct DeviceList: Decodable {
        let devices: [String: [Device]]
    }

    static func item(from data: Data) throws -> DiskCleanupItem? {
        let list: DeviceList
        do {
            list = try JSONDecoder().decode(DeviceList.self, from: data)
        } catch {
            throw DiskCleanupError.command("simctl list devices returned an answer DevHub cannot read.")
        }
        let devices = list.devices.values.flatMap { $0 }.filter { ($0.isAvailable ?? false) == false }
        guard devices.isEmpty == false else { return nil }
        let sizes = devices.compactMap(\.dataPathSize)
        return DiskCleanupItem(
            id: DiskCleanupKind.unavailableSimulators.rawValue,
            kind: .unavailableSimulators,
            paths: devices.compactMap(\.dataPath),
            count: devices.count,
            size: sizes.isEmpty ? nil : sizes.reduce(0, +)
        )
    }
}
