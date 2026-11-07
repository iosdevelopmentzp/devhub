import Foundation
import DevHubDomain

enum DevicectlListParser {
    private struct Listing: Decodable {
        let result: Result
    }

    private struct Result: Decodable {
        let devices: [Device]
    }

    private struct Device: Decodable {
        let identifier: String
        let connectionProperties: Connection?
        let deviceProperties: Properties?
        let hardwareProperties: Hardware?
    }

    private struct Connection: Decodable {
        let tunnelState: String?
    }

    private struct Properties: Decodable {
        let name: String?
        let osVersionNumber: String?
    }

    private struct Hardware: Decodable {
        let platform: String?
        let deviceType: String?
        let udid: String?
        let reality: String?
        let marketingName: String?
    }

    private static let platforms: Set<String> = ["iOS", "iPadOS"]
    private static let deviceTypes: Set<String> = ["iPhone", "iPad"]

    static func parse(_ data: Data) throws -> [Simulator] {
        let listing: Listing
        do {
            listing = try JSONDecoder().decode(Listing.self, from: data)
        } catch {
            throw DeviceError.malformedList
        }
        return listing.result.devices
            .filter(isPhone)
            .map(simulator)
            .sorted { lhs, rhs in
                if lhs.state != rhs.state { return lhs.state == .booted }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    private static func isPhone(_ device: Device) -> Bool {
        guard let hardware = device.hardwareProperties else { return false }
        guard hardware.reality == nil || hardware.reality == "physical" else { return false }
        return platforms.contains(hardware.platform ?? "") && deviceTypes.contains(hardware.deviceType ?? "")
    }

    private static func simulator(_ device: Device) -> Simulator {
        let hardware = device.hardwareProperties
        let name = device.deviceProperties?.name?.trimmed ?? ""
        let platform = hardware?.platform ?? "iOS"
        let version = device.deviceProperties?.osVersionNumber
        return Simulator(
            id: hardware?.udid ?? device.identifier,
            name: name.isEmpty ? (hardware?.marketingName ?? hardware?.deviceType ?? "Device") : name,
            kind: hardware?.deviceType == "iPad" ? .pad : .phone,
            state: device.connectionProperties?.tunnelState == "connected" ? .booted : .shutdown,
            isFavorite: false,
            isPhysical: true,
            runtime: version.map { "\(platform) \($0)" } ?? platform
        )
    }
}
