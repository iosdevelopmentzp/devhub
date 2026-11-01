import Foundation

package protocol SimulatorSettingsRepository: Sendable {
    func apply(_ setting: SimulatorSetting, udid: String) async throws
    func screenshot(udid: String, to path: String) async throws
    func record(udid: String, to path: String, onStarted: @escaping @Sendable () -> Void) async throws
}
