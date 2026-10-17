import Foundation

package struct SimulatorIdentitySettings: Codable, Hashable, Sendable {
    package var desiredDeviceID: String?
    package var desiredEnvironment: String?
    package var appliedDeviceID: String?
    package var hasApplied: Bool

    package init(desiredDeviceID: String? = nil, desiredEnvironment: String? = nil, appliedDeviceID: String? = nil, hasApplied: Bool) {
        self.desiredDeviceID = desiredDeviceID
        self.desiredEnvironment = desiredEnvironment
        self.appliedDeviceID = appliedDeviceID
        self.hasApplied = hasApplied
    }
}
