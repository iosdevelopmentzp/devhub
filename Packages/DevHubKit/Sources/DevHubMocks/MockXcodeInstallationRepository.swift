import Foundation
import DevHubDomain

struct MockXcodeInstallationRepository: XcodeInstallationRepository {

    func installations() async throws -> [XcodeInstallation] {
        MockData.xcodeInstallations
    }

    func selectedDeveloperDir() async throws -> String? {
        MockData.xcodeInstallations.last?.developerDir
    }

    func installation(atDeveloperDir path: String) async throws -> XcodeInstallation? {
        MockData.xcodeInstallations.first { $0.developerDir == path }
    }
}
