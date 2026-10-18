import Foundation

package struct DoctorTool: Hashable, Sendable {
    package var name: String
    package var versionArguments: [String]
    package var purpose: String
    package var installCommand: String

    package init(name: String, versionArguments: [String], purpose: String, installCommand: String) {
        self.name = name
        self.versionArguments = versionArguments
        self.purpose = purpose
        self.installCommand = installCommand
    }
}
