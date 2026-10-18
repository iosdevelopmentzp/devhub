import Foundation

package protocol SimulatorMessagingRepository: Sendable {
    func openURL(_ url: String, udid: String) async throws
    func sendPush(_ payload: String, bundleID: String, udid: String) async throws
    func urlSchemes(bundleID: String, udid: String) async -> [String]
}
