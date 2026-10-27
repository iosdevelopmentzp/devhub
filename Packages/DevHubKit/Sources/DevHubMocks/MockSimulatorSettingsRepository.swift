import Foundation
import DevHubDomain

struct MockSimulatorSettingsRepository: SimulatorSettingsRepository {
    func apply(_ setting: SimulatorSetting, udid: String) async throws {
        try? await Task.sleep(for: .milliseconds(200))
    }

    func screenshot(udid: String, to path: String) async throws {
        try? await Task.sleep(for: .milliseconds(200))
    }
}
