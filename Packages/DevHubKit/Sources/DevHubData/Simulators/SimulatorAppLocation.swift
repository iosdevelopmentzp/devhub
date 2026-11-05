import Foundation
import DevHubDomain

enum SimulatorAppLocation: Equatable {
    case simulator(path: String)
    case deviceHub(path: String)
    case unknown

    static let deviceHubBundleID = "com.apple.dt.Devices"

    static func find(developerDir: String?, exists: (String) -> Bool) -> SimulatorAppLocation {
        guard let developerDir, developerDir.isEmpty == false else { return .unknown }
        let simulator = (developerDir as NSString).appendingPathComponent("Applications/Simulator.app")
        if exists(simulator) {
            return .simulator(path: simulator)
        }
        let xcode = DeveloperDirPolicy.appPath(ofDeveloperDir: developerDir)
        let deviceHub = (xcode as NSString).appendingPathComponent("Contents/Applications/DeviceHub.app")
        if exists(deviceHub) {
            return .deviceHub(path: deviceHub)
        }
        return .unknown
    }

    static func deviceHubURL(udid: String) -> String {
        "devices://device/open?id=\(udid)"
    }

    var app: SimulatorApp {
        switch self {
        case .deviceHub: .deviceHub
        case .simulator, .unknown: .simulator
        }
    }
}
