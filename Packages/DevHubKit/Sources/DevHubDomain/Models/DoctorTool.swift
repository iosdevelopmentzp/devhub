import Foundation

package struct DoctorTool: Hashable, Sendable {
    package var name: String
    package var versionArguments: [String]
    package var purpose: String
    package var installCommand: String
    package var minimumMajorVersion: Int? = nil
    package var upgradeCommand: String? = nil

    package init(name: String, versionArguments: [String], purpose: String, installCommand: String, minimumMajorVersion: Int? = nil, upgradeCommand: String? = nil) {
        self.name = name
        self.versionArguments = versionArguments
        self.purpose = purpose
        self.installCommand = installCommand
        self.minimumMajorVersion = minimumMajorVersion
        self.upgradeCommand = upgradeCommand
    }
}
