import Foundation

package enum CleanInstallPolicy {

    package static func needsCleanInstall(
        identity: AppIdentity?,
        settings: SimulatorIdentitySettings,
        desiredDeviceID: String?,
        savedDeviceIDs: [String]
    ) -> Bool {
        guard let identity, identity.isInstalled else { return false }
        let hasAppliedOverride = settings.hasApplied && settings.appliedDeviceID != nil
        let actual = identity.lastDeviceID ?? (settings.hasApplied ? settings.appliedDeviceID : nil)
        if let desiredDeviceID {
            return actual != desiredDeviceID
        }
        guard let actual else { return hasAppliedOverride }
        return isOverrideID(actual, savedDeviceIDs: savedDeviceIDs) || hasAppliedOverride
    }

    package static func isOverrideID(_ deviceID: String, savedDeviceIDs: [String]) -> Bool {
        savedDeviceIDs.contains(deviceID) || UUID(uuidString: deviceID) == nil
    }
}
