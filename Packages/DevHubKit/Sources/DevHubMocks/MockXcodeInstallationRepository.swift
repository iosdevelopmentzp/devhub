import Foundation
import DevHubDomain

struct MockXcodeInstallationRepository: XcodeInstallationRepository {

    func installations() async throws -> [XcodeInstallation] {
        MockData.xcodeInstallations
    }

    func selectedDeveloperDir() async throws -> String? {
        MockData.xcodeInstallations.last?.developerDir
    }
}
