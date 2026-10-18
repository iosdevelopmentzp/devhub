import Foundation
import DevHubDomain

struct MockSimulatorMessagingRepository: SimulatorMessagingRepository {

    func openURL(_ url: String, udid: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func sendPush(_ payload: String, bundleID: String, udid: String) async throws {
        try await Task.sleep(for: .milliseconds(300))
    }

    func urlSchemes(bundleID: String, udid: String) async -> [String] {
        ["example", "example-chat"]
    }
}
