import Foundation
import DevHubDomain

struct MockUpdateRepository: UpdateRepository {

    func installed() async throws -> InstalledBuild? {
        nil
    }

    func check(installed: InstalledBuild) async throws -> UpdateCheck {
        .upToDate
    }

    func start(installed: InstalledBuild) async throws {}

    func status() async throws -> UpdateStatus? {
        nil
    }

    func isUpdateRunning() async -> Bool {
        false
    }

    func clearStatus() async throws {}

    func log() async throws -> String? {
        nil
    }
}
