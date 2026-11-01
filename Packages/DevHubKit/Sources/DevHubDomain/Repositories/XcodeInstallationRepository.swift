import Foundation

package protocol XcodeInstallationRepository: Sendable {
    func installations() async throws -> [XcodeInstallation]
    func selectedDeveloperDir() async throws -> String?
}
