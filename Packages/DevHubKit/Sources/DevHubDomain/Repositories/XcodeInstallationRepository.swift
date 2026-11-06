import Foundation

package protocol XcodeInstallationRepository: Sendable {
    func installations() async throws -> [XcodeInstallation]
    func selectedDeveloperDir() async throws -> String?
    func installation(atDeveloperDir path: String) async throws -> XcodeInstallation?
}
